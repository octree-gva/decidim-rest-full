# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Jobs::JobsController do
  path "/jobs/{id}" do
    get "Poll API job" do
      tags "Jobs"
      produces "application/json"
      operationId "getJob"
      description <<~TXT.strip
        Poll job status with the UUID from HTTP 202 responses. No Bearer header: capability is solely the opaque UUID scoped by request host / organization.
      TXT

      security []

      parameter name: :id, in: :path, required: true, schema: {
        type: :string,
        format: :uuid,
        description: "Job UUID (`job_id` from the asynchronous response body)"
      }

      let!(:organization) { create(:organization, available_locales: ["en"]) }
      let!(:user) { create(:user, organization:, locale: "en", confirmed_at: Time.zone.now) }
      let!(:api_client) do
        c = create(:api_client, organization:, scopes: ["proposals"])
        c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "proposals.draft")]
        c.save!
        c
      end
      let!(:bearer_token) do
        create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client)
      end

      before { host! organization.host }

      response "200", "job state" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_detail)

        context "when complete" do
          let!(:job_row) do
            Decidim::RestFull::ApiJob.compat_create!(
              decidim_organization_id: organization.id,
              doorkeeper_access_token_id: bearer_token.id,
              oauth_application_id: api_client.id,
              resource_owner_id: user.id,
              command_key: "draft_proposals#create",
              status: "completed",
              payload: { "path" => {}, "data" => {} },
              result: { "data" => { "ok" => true } }
            )
          end
          let(:id) { job_row.id }

          run_test!(example_name: :poll_completed) do
            parsed = response.parsed_body
            expect(parsed["status"]).to eq("completed")
            expect(parsed["data"]).to eq({ "ok" => true })
            expect(parsed.dig("links", "self", "href")).to end_with("/jobs/#{job_row.id}")
          end
        end
      end

      response "404", "Job not found" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

        context "when id is not a UUID" do
          let(:id) { "not-a-uuid" }

          run_test!(example_name: :job_bad_id_shape) do
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when uuid unknown" do
          let(:id) { SecureRandom.uuid }

          run_test!(example_name: :job_unknown_uuid) do
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end
  end
end
