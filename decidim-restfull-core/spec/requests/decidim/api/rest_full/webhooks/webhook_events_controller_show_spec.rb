# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Webhooks::WebhookEventsController do
  path "/webhook_events/{event_type}" do
    get "Show webhook event example payload" do
      tags "Webhooks"
      produces "application/json"
      operationId "showWebhookEventExample"
      description <<~README
        Returns an example delivery envelope for the given event type, built by serializing a real
        resource in the current organization (same serializers used for outbound delivery).
      README
      parameter name: :event_type, in: :path, type: :string, required: true,
                description: "Event key (e.g. proposal_creation.succeeded)"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Webhooks::WebhookEventsController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["webhooks"],
        permissions: ["webhooks.read"]
      ) do
        let(:event_type) { "proposal_creation.succeeded" }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, :published, component:) }

        response "200", "Example payload" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_delivery_envelope)

          run_test!(example_name: :ok) do |example|
            body = JSON.parse(example.body)
            expect(body["type"]).to eq("proposal_creation.succeeded")
            expect(body["data"]["type"]).to eq("proposal")
            expect(body["data"]["id"]).to eq(proposal.id.to_s)
          end
        end

        response "404", "Unknown event" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)
          let(:event_type) { "does.not.exist" }

          run_test!(example_name: :not_found) do
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end
  end
end
