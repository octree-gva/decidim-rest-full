# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Organizations::OrganizationsController do
  path "/organizations" do
    get "Organizations" do
      tags "Organizations"
      produces "application/json"
      operationId "listOrganizations"
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
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:organization_index_response)

          context "with locale[] filter translated results" do
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :ok)
          end

          context "when another tenant exists", if: Gem.loaded_specs.has_key?("ros-apartment") do
            let!(:other_organization) do
              org = create(:organization, host: "org-b.example.org", available_locales: ["en"])
              Apartment::Tenant.switch!(Decidim::Apartment::DistributionKey.for_host(organization.host).key)
              org
            end
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test! do |example|
              hosts = JSON.parse(example.body).fetch("data").map { |row| row.dig("attributes", "host") }
              expect(hosts).to include(organization.host)
              expect(hosts).not_to include(other_organization.host)
            end
          end
        end
      end

      it_behaves_like "unauthorized when no Bearer token"
    end
  end
end
