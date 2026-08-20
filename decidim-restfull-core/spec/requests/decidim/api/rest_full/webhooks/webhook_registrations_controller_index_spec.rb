# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController do
  path "/webhook_registrations" do
    get "List webhook registrations" do
      tags "Webhooks"
      produces "application/json"
      operationId "listWebhookRegistrations"
      description "List webhook registrations owned by the current API client."
      it_behaves_like "paginated params"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["webhooks"],
        permissions: ["webhooks.read"]
      ) do
        let!(:webhook_registration) do
          create(:webhook_registration, api_client:, url: "https://example.org/hooks/mine")
        end
        let!(:other_client) { create(:api_client, organization:, scopes: ["webhooks"]) }
        let!(:other_registration) do
          create(:webhook_registration, api_client: other_client, url: "https://example.org/hooks/other")
        end

        response "200", "Registrations listed" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_index_response)

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            ids = data.map { |d| d["id"] }
            expect(ids).to include(webhook_registration.id.to_s)
            expect(ids).not_to include(other_registration.id.to_s)
            expect(data.first["attributes"]).not_to have_key("signing_secret")
          end
        end
      end
    end
  end
end
