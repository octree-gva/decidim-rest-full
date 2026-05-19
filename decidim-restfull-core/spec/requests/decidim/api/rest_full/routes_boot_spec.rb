# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- integration contract: metagem boot + route registry
RSpec.describe "Decidim RestFull routes boot (metagem)" do
  include ActiveJob::TestHelper

  let!(:organization) { create(:organization, available_locales: ["en"]) }
  let!(:user) { create(:user, organization:, confirmed_at: Time.zone.now) }
  let!(:participatory_process) { create(:participatory_process, organization:) }
  let!(:proposal_component) do
    create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now)
  end
  let!(:api_client) do
    c = create(:api_client, organization:, scopes: ["proposals"])
    c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "proposals.draft")]
    c.save!
    c
  end
  let!(:token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client) }

  let(:api_prefix) { "/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }

  before { host!(organization.host) }

  it "draws routes via Decidim::RestFull::Routes.draw! and accepts async draft_proposals#create" do
    expect(Decidim::RestFull::Routes.applied?).to be(true)

    path = "#{api_prefix}/draft_proposals"
    expect(
      Decidim::Core::Engine.routes.routes.map { |r| r.path.spec.to_s }
    ).to include(a_string_matching(%r{/api/rest_full/v[\d.]+/draft_proposals}))

    Decidim::Proposals::Proposal.where(decidim_component_id: proposal_component.id).delete_all

    expect do
      post(
        path,
        params: { data: { component_id: proposal_component.id } }.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "Authorization" => "Bearer #{token.token}"
        }
      )
    end.to have_enqueued_job(Decidim::RestFull::ExecuteApiJobJob)

    expect(response).to have_http_status(:accepted)
    expect(response.parsed_body["job_id"]).to be_present
    expect(response.parsed_body.keys).not_to include("poll_secret")
    expect(response.parsed_body.dig("links", "self", "href")).to end_with("/jobs/#{response.parsed_body["job_id"]}")
  end
end
# rubocop:enable RSpec/DescribeClass
