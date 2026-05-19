# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Jobs::JobsController do
  path "/jobs" do
    get "List API jobs" do
      tags "Jobs"
      produces "application/json"
      operationId "listJobs"
      description <<~README
        Returns async jobs for the same OAuth application, resource owner (when applicable), and organization as the Bearer token used to originate those jobs.

        ### Pagination
        `page` defaults to `1`; `per_page` defaults to `25` and is clamped to **100**.

        ### Filters
        - `filter[command_key]`: job name (e.g. `draft_proposals#create`, `forms/questions#create`)
        - `filter[status]`: `pending`, `processing`, `completed`, or `failed`

        ### Conditional GET
        Supports `ETag` / `If-None-Match` on the collection.

        ### Access
        Bearer token required (same OAuth context as the jobs being listed).
      README

      let(:Authorization) { "Bearer #{bearer_token.token}" }
      let!(:bearer_token) do
        create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client)
      end
      let!(:api_client) do
        c = create(:api_client, organization:, scopes: ["proposals"])
        c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "proposals.draft")]
        c.save!
        c
      end
      let!(:user) { create(:user, organization:, locale: "en", confirmed_at: Time.zone.now) }
      let!(:organization) { create(:organization, available_locales: ["en"]) }

      before { host! organization.host }

      it_behaves_like "filtered params", filter: "command_key", item_schema: { type: :string }, only: :string
      it_behaves_like "filtered params", filter: "status", item_schema: { type: :string, enum: Decidim::RestFull::ApiJob::STATUSES }, only: :string

      security [
        { credentialFlowBearer: %w(proposals) },
        { resourceOwnerFlowBearer: %w(proposals) }
      ]

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true,
                description: "Bearer access token: `Bearer <token>`"

      it_behaves_like "paginated params"

      response "200", "jobs listed for oauth context" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_jobs_index_response)

        context "when listing jobs scoped to one OAuth application" do
          let!(:foreign_client) do
            c = create(:api_client, organization:, scopes: ["proposals"])
            c.permissions = [Decidim::RestFull::Core::Permission.new(permission: "proposals.draft")]
            c.save!
            c
          end
          let!(:foreign_token) do
            create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: foreign_client)
          end

          let!(:mine) do
            Decidim::RestFull::ApiJob.compat_create!(
              decidim_organization_id: organization.id,
              doorkeeper_access_token_id: bearer_token.id,
              oauth_application_id: api_client.id,
              resource_owner_id: user.id,
              command_key: "draft_proposals#create",
              status: "completed",
              payload: { "path" => {}, "data" => {} }
            )
          end
          let!(:other_app_job) do
            Decidim::RestFull::ApiJob.compat_create!(
              decidim_organization_id: organization.id,
              doorkeeper_access_token_id: foreign_token.id,
              oauth_application_id: foreign_client.id,
              resource_owner_id: user.id,
              command_key: "draft_proposals#create",
              status: "pending",
              payload: { "path" => {}, "data" => {} }
            )
          end

          let(:page) { 1 }
          let(:per_page) { 25 }

          run_test!(example_name: :ok_index) do
            ids = response.parsed_body["data"].map { |j| j["id"] }
            expect(ids).to contain_exactly(mine.id)
            meta = response.parsed_body["meta"]
            expect(meta["page"]).to eq(1)
            expect(meta["per_page"]).to eq(25)
          end
        end
      end

      response "401", "Unauthorized when Bearer missing" do
        let(:Authorization) { nil }

        security []
        produces "application/json"
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

        run_test!(example_name: :jobs_index_unauthenticated) do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
