# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- integration-style request examples
RSpec.describe "Decidim RestFull async jobs and conditional GET" do
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

  describe "async draft proposal create" do
    it "returns 202, enqueues job, and job completes with serialized draft" do
      Decidim::Proposals::Proposal.where(decidim_component_id: proposal_component.id).delete_all

      expect do
        post(
          "#{api_prefix}/draft_proposals",
          params: { data: { component_id: proposal_component.id } }.to_json,
          headers: {
            "CONTENT_TYPE" => "application/json",
            "Authorization" => "Bearer #{token.token}"
          }
        )
      end.to have_enqueued_job(Decidim::RestFull::ExecuteApiJobJob)

      expect(response).to have_http_status(:accepted)
      parsed = response.parsed_body
      expect(parsed["job_id"]).to be_present
      expect(parsed["status"]).to eq("pending")
      expect(parsed.dig("links", "self", "href")).to end_with("/jobs/#{parsed["job_id"]}")
      expect(parsed["poll_url"]).to eq(parsed.dig("links", "self", "href"))

      perform_enqueued_jobs

      get("#{api_prefix}/jobs/#{parsed["job_id"]}")
      expect(response).to have_http_status(:ok)
      job = response.parsed_body
      expect(job["status"]).to eq("completed")
      expect(job["data"]).to be_a(Hash)
      expect(job["data"]["data"]).to be_present
    end
  end

  describe "jobs index scoped to OAuth application and resource owner" do
    it "lists jobs for any access token from the same client and user" do
      other = create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client)
      foreign_client = create(:api_client, organization:, scopes: ["proposals"])
      foreign_token = create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: foreign_client)
      Decidim::RestFull::ApiJob.compat_create!(
        decidim_organization_id: organization.id,
        doorkeeper_access_token_id: foreign_token.id,
        oauth_application_id: foreign_token.application_id,
        resource_owner_id: foreign_token.resource_owner_id,
        command_key: "draft_proposals#create",
        status: "completed",
        payload: { "path" => {}, "data" => {} }
      )
      mine = Decidim::RestFull::ApiJob.compat_create!(
        decidim_organization_id: organization.id,
        doorkeeper_access_token_id: token.id,
        oauth_application_id: token.application_id,
        resource_owner_id: token.resource_owner_id,
        command_key: "draft_proposals#create",
        status: "pending",
        payload: { "path" => {}, "data" => {} }
      )
      other_job = Decidim::RestFull::ApiJob.compat_create!(
        decidim_organization_id: organization.id,
        doorkeeper_access_token_id: other.id,
        oauth_application_id: other.application_id,
        resource_owner_id: other.resource_owner_id,
        command_key: "draft_proposals#create",
        status: "completed",
        payload: { "path" => {}, "data" => {} }
      )

      get("#{api_prefix}/jobs", headers: { "Authorization" => "Bearer #{token.token}" })
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["data"].map { |j| j["id"] }
      expect(ids).to contain_exactly(mine.id, other_job.id)
    end
  end

  describe "job show" do
    it "returns job status given only the job UUID (no Bearer)" do
      job = Decidim::RestFull::ApiJob.compat_create!(
        decidim_organization_id: organization.id,
        doorkeeper_access_token_id: token.id,
        oauth_application_id: token.application_id,
        resource_owner_id: token.resource_owner_id,
        command_key: "draft_proposals#create",
        status: "completed",
        payload: { "path" => {}, "data" => {} },
        result: { "data" => { "ok" => true } }
      )

      get("#{api_prefix}/jobs/#{job.id}")
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("completed")
    end

    it "responds 404 for non-uuid id (no enumeration signal)" do
      get("#{api_prefix}/jobs/not-a-uuid")
      expect(response).to have_http_status(:not_found)
    end

    it "responds 404 when job belongs to another organization (same UUID never visible on wrong host)" do
      other_org = create(:organization, host: "other.example.local", available_locales: ["en"])
      foreign_user = create(:user, organization: other_org, confirmed_at: Time.zone.now)
      foreign_api = create(:api_client, organization: other_org, scopes: ["proposals"])
      foreign_api.permissions = [Decidim::RestFull::Core::Permission.new(permission: "proposals.draft")]
      foreign_api.save!
      foreign_tok = create(:oauth_access_token, scopes: "proposals", resource_owner_id: foreign_user.id, application: foreign_api)
      job = Decidim::RestFull::ApiJob.compat_create!(
        decidim_organization_id: other_org.id,
        doorkeeper_access_token_id: foreign_tok.id,
        oauth_application_id: foreign_tok.application_id,
        resource_owner_id: foreign_tok.resource_owner_id,
        command_key: "draft_proposals#create",
        status: "completed",
        payload: { "path" => {}, "data" => {} }
      )

      get("#{api_prefix}/jobs/#{job.id}")
      expect(response).to have_http_status(:not_found)
    end

    it "responds 404 for unknown uuid" do
      get("#{api_prefix}/jobs/#{SecureRandom.uuid}")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "proposal show conditional GET" do
    let!(:read_client) do
      c = create(:api_client, organization:, scopes: ["proposals"])
      c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "proposals.read")]
      c.save!
      c
    end
    let!(:read_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: read_client) }
    let!(:proposal) { create(:proposal, component: proposal_component) }

    it "returns 304 when If-None-Match matches fingerprint" do
      path = "#{api_prefix}/proposals/#{proposal.id}"
      qs = "?component_id=#{proposal_component.id}&space_id=#{participatory_process.id}&space_manifest=participatory_processes"
      headers = { "Authorization" => "Bearer #{read_token.token}" }

      get(path + qs, headers:)
      expect(response).to have_http_status(:ok)
      etag = response.headers["ETag"]
      expect(etag).to be_present

      get(path + qs, headers: headers.merge("If-None-Match" => etag))
      expect(response).to have_http_status(:not_modified)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
