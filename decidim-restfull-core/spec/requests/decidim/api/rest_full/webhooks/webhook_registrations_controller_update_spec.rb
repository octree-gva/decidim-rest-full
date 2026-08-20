# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController do
  path "/webhook_registrations/{id}" do
    put "Update webhook registration" do
      tags "Webhooks"
      produces "application/json"
      consumes "application/json"
      operationId "updateWebhookRegistration"
      description "Update URL and subscriptions. Does not rotate the signing secret."
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_create_body) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController,
        action: :update,
        security_types: [:credentialFlow],
        scopes: ["webhooks"],
        permissions: ["webhooks.write"]
      ) do
        let(:event_key) { "proposal_creation.succeeded" }
        let!(:webhook_registration) do
          create(:webhook_registration, api_client:, url: "https://example.org/hooks/old", subscriptions: [event_key])
        end
        let(:id) { webhook_registration.id }
        let(:body) do
          {
            data: {
              attributes: {
                url: "https://example.org/hooks/updated",
                subscriptions: [event_key]
              }
            }
          }
        end

        before do
          api_client.permissions.create!(permission: event_key, is_event: true)
        end

        response "200", "Registration updated" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_item_response)

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["url"]).to eq("https://example.org/hooks/updated")
            expect(data["attributes"]).not_to have_key("signing_secret")
            expect(webhook_registration.reload.url).to eq("https://example.org/hooks/updated")
          end
        end
      end
    end
  end
end
