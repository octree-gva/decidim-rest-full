# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::ExecuteApiJobJob do
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

  it "runs draft create and marks job completed" do
    Decidim::Proposals::Proposal.where(decidim_component_id: proposal_component.id).delete_all

    job = Decidim::RestFull::ApiJob.compat_create!(
      decidim_organization_id: organization.id,
      doorkeeper_access_token_id: token.id,
      oauth_application_id: token.application_id,
      resource_owner_id: token.resource_owner_id,
      command_key: "draft_proposals#create",
      status: "pending",
      payload: {
        "path" => {
          "component_id" => proposal_component.id,
          "space_manifest" => "participatory_processes",
          "space_id" => participatory_process.id
        },
        "data" => { "component_id" => proposal_component.id }
      }
    )

    described_class.perform_now(job.id)
    job.reload
    expect(job.status).to eq("completed")
    expect(job.result["data"]).to be_a(Hash)
  end
end
