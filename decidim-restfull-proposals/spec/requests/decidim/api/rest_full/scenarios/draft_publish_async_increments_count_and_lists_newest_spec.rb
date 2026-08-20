# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- behaviour scenario (multi-step HTTP)
RSpec.describe "Draft publish async increments component count and lists newest" do
  include ActiveJob::TestHelper

  let!(:organization) { create(:organization, available_locales: ["en"], default_locale: "en") }
  let!(:participatory_process) { create(:participatory_process, organization:) }
  let!(:proposal_component) do
    create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now)
  end
  let!(:existing_proposal) do
    create(:proposal, component: proposal_component, published_at: 2.days.ago)
  end

  let!(:api_client) do
    c = create(:api_client, organization:, scopes: %w(oauth public proposals))
    c.permissions = [
      Decidim::RestFull::Core::Permission.new(permission: "oauth.impersonate"),
      Decidim::RestFull::Core::Permission.new(permission: "public.component.read"),
      Decidim::RestFull::Core::Permission.new(permission: "proposals.draft"),
      Decidim::RestFull::Core::Permission.new(permission: "proposals.read")
    ]
    c.save!
    c
  end

  let!(:credential_token) do
    create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client)
  end

  let(:api_prefix) { "/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:nickname) { "author#{SecureRandom.hex(4)}" }
  let(:email) { "#{nickname}@example.org" }

  before { host!(organization.host) }

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def component_resources_count(token)
    get(
      "#{api_prefix}/components/proposal_components/#{proposal_component.id}",
      headers: bearer(token)
    )
    expect(response).to have_http_status(:ok)
    response.parsed_body.dig("data", "relationships", "resources", "meta", "count")
  end

  # rubocop:disable RSpec/ExampleLength -- end-to-end publish scenario
  it "upserts user, fills draft, publishes async, then count and newest list update" do
    post(
      "#{api_prefix}/oauth/token",
      params: {
        grant_type: "password",
        auth_type: "impersonate",
        username: nickname,
        client_id: api_client.client_id,
        client_secret: api_client.client_secret,
        scope: "proposals",
        meta: {
          register_on_missing: true,
          email:,
          skip_confirmation_on_register: true
        }
      }.to_json,
      headers: json_headers
    )
    expect(response).to have_http_status(:ok)
    user_token = response.parsed_body["access_token"]
    expect(user_token).to be_present

    post(
      "#{api_prefix}/draft_proposals/sync",
      params: { data: { component_id: proposal_component.id } }.to_json,
      headers: json_headers.merge(bearer(user_token))
    )
    expect(response).to have_http_status(:ok)
    draft_id = response.parsed_body.dig("data", "id")
    expect(draft_id).to be_present
    expect(response.parsed_body.dig("data", "meta", "publishable")).to be(false)

    put(
      "#{api_prefix}/draft_proposals/#{draft_id}/sync",
      params: {
        data: {
          title: "This is a valid proposal title sample",
          body: "I am quite a valid proposal, with one sentence that is long enough to be valid I think."
        }
      }.to_json,
      headers: json_headers.merge(bearer(user_token))
    )
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "meta", "publishable")).to be(true)

    count_before = component_resources_count(credential_token.token)

    post(
      "#{api_prefix}/draft_proposals/#{draft_id}/publish",
      headers: bearer(user_token)
    )
    expect(response).to have_http_status(:accepted)
    job_id = response.parsed_body["job_id"]
    expect(job_id).to be_present

    perform_enqueued_jobs

    get("#{api_prefix}/jobs/#{job_id}")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("completed")

    expect(component_resources_count(credential_token.token)).to eq(count_before + 1)

    proposals_token = create(
      :oauth_access_token,
      scopes: "proposals",
      resource_owner_id: nil,
      application: api_client
    )
    get(
      "#{api_prefix}/proposals",
      params: {
        order: "published_at",
        order_direction: "desc",
        per_page: 1,
        component_id: proposal_component.id,
        space_id: participatory_process.id,
        space_manifest: "participatory_processes"
      },
      headers: bearer(proposals_token.token)
    )
    expect(response).to have_http_status(:ok)
    listed = response.parsed_body["data"]
    expect(listed.size).to eq(1)
    expect(listed.first["id"].to_s).to eq(draft_id.to_s)
    expect(listed.first.dig("meta", "published")).to be_truthy
  end
  # rubocop:enable RSpec/ExampleLength
end
# rubocop:enable RSpec/DescribeClass
