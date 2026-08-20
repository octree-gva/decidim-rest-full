# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController do
  path "/webhook_registrations/{id}" do
    delete "Delete webhook registration" do
      tags "Webhooks"
      produces "application/json"
      operationId "deleteWebhookRegistration"
      parameter name: :id, in: :path, type: :string, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Webhooks::WebhookRegistrationsController,
        action: :destroy,
        security_types: [:credentialFlow],
        scopes: ["webhooks"],
        permissions: ["webhooks.destroy"]
      ) do
        let!(:webhook_registration) do
          create(:webhook_registration, api_client:, url: "https://example.org/hooks/delete")
        end
        let(:id) { webhook_registration.id }

        response "204", "Registration deleted" do
          run_test!(example_name: :ok) do
            expect(response).to have_http_status(:no_content)
            expect(Decidim::RestFull::Core::WebhookRegistration.find_by(id: webhook_registration.id)).to be_nil
          end
        end
      end
    end
  end
end
