# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController do
  path "/webhook_registrations" do
    post "Create webhook registration" do
      tags "Webhooks"
      produces "application/json"
      consumes "application/json"
      operationId "createWebhookRegistration"
      description <<~README
        Create a webhook registration for the current API client.
        The signing secret is returned **only in this response** — store it to verify HMAC signatures.
        Subscriptions must be event permissions already granted on the API client.
      README
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_create_body) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController,
        action: :create,
        security_types: [:credentialFlow],
        scopes: ["webhooks"],
        permissions: ["webhooks.write"]
      ) do
        let(:event_key) { "proposal_creation.succeeded" }
        let(:body) do
          {
            data: {
              attributes: {
                url: "https://example.org/hooks/new",
                subscriptions: [event_key]
              }
            }
          }
        end

        before do
          api_client.permissions.create!(permission: event_key, is_event: true)
        end

        response "201", "Registration created" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_item_response)

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["url"]).to eq("https://example.org/hooks/new")
            expect(data["attributes"]["subscriptions"]).to eq([event_key])
            expect(data["attributes"]["signing_secret"]).to be_present
            expect(data["attributes"]["signing_secret"].length).to eq(64)
          end
        end

        response "400", "Invalid subscription" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)
          let(:body) do
            {
              data: {
                attributes: {
                  url: "https://example.org/hooks/bad",
                  subscriptions: ["not.an.event"]
                }
              }
            }
          end

          run_test!(example_name: :bad_request) do
            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end
  end
end
