# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Jobs::JobsController do
  path "/jobs/{id}" do
    delete "Delete API job" do
      tags "Jobs"
      operationId "deleteJob"
      description <<~TXT.strip
        Remove a job record from the index. Only jobs created under the same OAuth application and resource owner as the Bearer token may be deleted. Does not cancel Sidekiq work already in flight for `processing` jobs.
      TXT

      security [
        { credentialFlowBearer: %w(proposals) },
        { resourceOwnerFlowBearer: %w(proposals) }
      ]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, required: true, schema: { type: :string, format: :uuid }

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
      let(:Authorization) { "Bearer #{bearer_token.token}" }

      before { host! organization.host }

      response "204", "job deleted" do
        let!(:job) do
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
        let(:id) { job.id }

        run_test!(example_name: :deleted) do
          expect(response).to have_http_status(:no_content)
          expect(Decidim::RestFull::ApiJob.find_by(id: job.id)).to be_nil
        end
      end
    end
  end
end
