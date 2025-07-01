# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Organizations::OrganizationsController do
  path "/organizations/{id}" do
    get "Organization" do
      tags "Organizations"
      produces "application/json"
      operationId "organization"
      description "Show organization"
      it_behaves_like "localized params"
      parameter name: :id, in: :path, type: :string, required: true, description: "The ID of the organization"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Organizations::OrganizationsController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["system"],
        permissions: ["system.organizations.read"]
      ) do
        it_behaves_like "localized endpoint"
        let(:organization) { create(:organization) }
        let(:id) { organization.id }
        response "200", "Organization shown" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:organization_item_response)

          context "with locale[] filter translated results" do
            let(:"locales[]") { %w(en fr) }

            run_test!(example_name: :ok)
          end
        end

        response "404", "Organization Not Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "when id=bad_string" do
            let(:id) { "bad_string" }

            run_test!
          end

          context "when id=not_found" do
            let(:id) { Decidim::Organization.last.id + 10 }

            run_test!(example_name: :not_found)
          end
        end
      end
    end
  end
end
