# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- behaviour scenario (multi-step HTTP)
#
# Process-lifecycle webhook catalog entry is still absent (SpaceSerializer has no phase;
# WebhookDispatcher only maps proposal events). This scenario covers phase-driven
# proposal-component meta (votes_enabled / can_vote) plus existing proposal webhook plumbing smoke.
RSpec.describe "Participatory process phase change drives proposal component meta (+ webhook smoke)" do
  include ActiveJob::TestHelper

  let!(:organization) { create(:organization, available_locales: %w(en)) }
  let!(:participatory_process) { create(:participatory_process, organization:) }
  let!(:propose_phase) { create(:participatory_process_step, :active, participatory_process:, position: 0) }
  let!(:vote_phase) { create(:participatory_process_step, active: false, participatory_process:, position: 1) }
  let!(:voter) { create(:user, :confirmed, organization:, nickname: "phase#{SecureRandom.hex(4)}") }

  let!(:proposal_component) do
    create(
      :proposal_component,
      participatory_space: participatory_process,
      step_settings: {
        propose_phase.id.to_s => { creation_enabled: true, votes_enabled: false },
        vote_phase.id.to_s => { creation_enabled: false, votes_enabled: true }
      },
      settings: { awesome_voting_manifest: :voting_cards }
    )
  end

  let!(:proposal) { create(:proposal, :accepted, component: proposal_component) }

  let!(:api_client) do
    c = create(:api_client, organization:, scopes: %w(public oauth proposals))
    c.permissions = [
      Decidim::RestFull::Core::Permission.new(permission: "public.component.read"),
      Decidim::RestFull::Core::Permission.new(permission: "oauth.impersonate"),
      Decidim::RestFull::Core::Permission.new(permission: "proposal_creation.succeeded")
    ]
    c.save!
    c
  end

  let!(:public_token) do
    create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client)
  end

  let!(:webhook) do
    create(:webhook_registration, api_client:, subscriptions: ["proposal_creation.succeeded"])
  end

  let(:api_prefix) { "/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }

  before { host!(organization.host) }

  def proposal_component_meta(token)
    get(
      "#{api_prefix}/components/proposal_components/#{proposal_component.id}",
      headers: { "Authorization" => "Bearer #{token}" }
    )
    expect(response).to have_http_status(:ok)
    response.parsed_body.dig("data", "meta")
  end

  it "flips votes meta when active step becomes VOTE, and enqueues proposal webhook job" do
    meta_propose = proposal_component_meta(public_token.token)
    expect(meta_propose["votes_enabled"]).to be(false)
    expect(meta_propose["can_vote"]).to be(false)

    propose_phase.update!(active: false)
    vote_phase.update!(active: true)
    participatory_process.reload
    proposal_component.reload

    post(
      "#{api_prefix}/oauth/token",
      params: {
        grant_type: "password",
        auth_type: "impersonate",
        username: voter.nickname,
        client_id: api_client.client_id,
        client_secret: api_client.client_secret,
        scope: "public"
      }.to_json,
      headers: json_headers
    )
    expect(response).to have_http_status(:ok)
    impersonation_token = response.parsed_body["access_token"]

    meta_vote = proposal_component_meta(impersonation_token)
    expect(meta_vote["votes_enabled"]).to be(true)
    expect(meta_vote["can_vote"]).to be(true)

    # Decidim command/event hooks use Notifications.publish (name, payload hash).
    expect do
      ActiveSupport::Notifications.publish(
        "decidim.events.proposals.proposal_published",
        { resource: proposal }
      )
    end.to have_enqueued_job(Decidim::RestFull::Proposals::ProposalWebhookJob).with(
      "proposal_creation.succeeded",
      proposal.id,
      organization.id
    )

    # Keep webhook registration in the graph so the smoke path stays realistic.
    expect(webhook.subscriptions).to include("proposal_creation.succeeded")
  end
end
# rubocop:enable RSpec/DescribeClass
