# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Organizations::OrganizationsController do
  path "/organizations" do
    get "Organizations" do
      tags "Organizations"
      produces "application/json"
      operationId "organizations"
      description "List available organizations"
      it_behaves_like "localized params"
      it_behaves_like "paginated params"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Organizations::OrganizationsController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["system"],
        permissions: ["system.organizations.read"]
      ) do
        it_behaves_like "localized endpoint"

        response "200", "Organizations listed" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:organization_index_response)

          context "with locale[] filter translated results" do
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :ok)
          end
        end
      end
    end
  end
end
