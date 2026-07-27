# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- behaviour scenario (multi-step HTTP)
RSpec.describe "Search vote-enabled component, impersonate, and vote" do
  let!(:organization) { create(:organization, available_locales: ["en"]) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:proposal_component) do
    create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process)
  end
  let!(:proposal) { create(:proposal, :accepted, component: proposal_component) }
  let!(:voter) { create(:user, :confirmed, organization:, nickname: "voter#{SecureRandom.hex(4)}") }

  let!(:api_client) do
    c = create(:api_client, organization:, scopes: %w(public oauth proposals))
    c.permissions = [
      Decidim::RestFull::Core::Permission.new(permission: "public.component.read"),
      Decidim::RestFull::Core::Permission.new(permission: "oauth.impersonate"),
      Decidim::RestFull::Core::Permission.new(permission: "proposals.vote")
    ]
    c.save!
    c
  end

  let!(:public_token) do
    create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client)
  end

  let(:api_prefix) { "/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }

  before { host!(organization.host) }

  it "finds the component, asserts voting meta, impersonates, and casts a sync vote" do
    get(
      "#{api_prefix}/components/search",
      params: { "filter[id_in][]" => [proposal_component.id] },
      headers: { "Authorization" => "Bearer #{public_token.token}" }
    )
    expect(response).to have_http_status(:ok)
    search_ids = response.parsed_body["data"].map { |row| row["id"].to_i }
    expect(search_ids).to include(proposal_component.id)

    get(
      "#{api_prefix}/components/proposal_components/#{proposal_component.id}",
      headers: { "Authorization" => "Bearer #{public_token.token}" }
    )
    expect(response).to have_http_status(:ok)
    meta = response.parsed_body.dig("data", "meta")
    expect(meta["votes_enabled"]).to be(true)
    expect(meta["can_vote"]).to be(true)

    post(
      "#{api_prefix}/oauth/token",
      params: {
        grant_type: "password",
        auth_type: "impersonate",
        username: voter.nickname,
        client_id: api_client.client_id,
        client_secret: api_client.client_secret,
        scope: "public proposals"
      }.to_json,
      headers: json_headers
    )
    expect(response).to have_http_status(:ok)
    impersonation_token = response.parsed_body["access_token"]
    expect(impersonation_token).to be_present

    get(
      "#{api_prefix}/components/proposal_components/#{proposal_component.id}",
      headers: { "Authorization" => "Bearer #{impersonation_token}" }
    )
    expect(response).to have_http_status(:ok)
    impersonated_meta = response.parsed_body.dig("data", "meta")
    expect(impersonated_meta["votes_enabled"]).to be(true)
    expect(impersonated_meta["can_vote"]).to be(true)

    post(
      "#{api_prefix}/vote_proposals/sync",
      params: { data: { weight: 1 }, proposal_id: proposal.id }.to_json,
      headers: json_headers.merge("Authorization" => "Bearer #{impersonation_token}")
    )
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "type")).to eq("vote_proposals")
  end
end
# rubocop:enable RSpec/DescribeClass
