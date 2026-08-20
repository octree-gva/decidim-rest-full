# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController do
  path "/webhook_registrations/{id}" do
    get "Show webhook registration" do
      tags "Webhooks"
      produces "application/json"
      operationId "showWebhookRegistration"
      parameter name: :id, in: :path, type: :string, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["webhooks"],
        permissions: ["webhooks.read"]
      ) do
        let!(:webhook_registration) do
          create(:webhook_registration, api_client:, url: "https://example.org/hooks/show")
        end
        let(:id) { webhook_registration.id }

        response "200", "Registration found" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_item_response)

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(webhook_registration.id.to_s)
            expect(data["attributes"]["url"]).to eq("https://example.org/hooks/show")
            expect(data["attributes"]).not_to have_key("signing_secret")
          end
        end

        response "404", "Not found for another API client" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)
          let!(:other_client) { create(:api_client, organization:, scopes: ["webhooks"]) }
          let!(:other_registration) do
            create(:webhook_registration, api_client: other_client, url: "https://example.org/hooks/foreign")
          end
          let(:id) { other_registration.id }

          run_test!(example_name: :not_found_other_client) do
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end
  end
end
