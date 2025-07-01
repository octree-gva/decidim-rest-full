# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Organizations::OrganizationExtendedDataController do
  path "/organizations/{id}/extended_data" do
    get "Organization extended data" do
      tags "Organizations Extended Data"
      produces "application/json"
      operationId "organizationData"
      description "Fetch organization extended data"
      parameter name: "object_path", in: :query, required: true, schema: { type: :string, description: "object path, in dot style, like foo.bar" }
      parameter name: "id", in: :path, schema: { type: :integer, description: "Id of the organization" }
      let(:organization) { create(:organization) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Organizations::OrganizationExtendedDataController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["system"],
        permissions: ["system.organization.extended_data.read"]
      ) do
        let!(:id) { organization.id }
        let!(:object_path) { "custom.data" }

        response "200", "Extended Data for a given object_path given" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:organization_extended_data)
          context "with extended_data={'foo' => {'bar' => 'true'}}, can access object_path=foo.bar" do
            before do
              organization.extended_data.update(data: { "foo" => { "bar" => "true" } })
            end

            let!(:object_path) { "foo.bar" }

            run_test! do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to eq("true")
            end
          end

          context "with extended_data={'personal' => {'birthday' => '1989-01-28'}}, can access object_path=personal" do
            before do
              organization.extended_data.update(data: { "personal" => { "birthday" => "1989-01-28" } })
            end

            let!(:object_path) { "personal" }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include({ "birthday" => "1989-01-28" })
            end
          end

          context "with extended_data=<whatever object>, can access object_path=." do
            before do
              organization.extended_data.update(data: { "personal" => { "birthday" => "1989-01-28" } })
            end

            let!(:object_path) { "." }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include({ "personal" => { "birthday" => "1989-01-28" } })
            end
          end
        end

        response "404", "Not Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "with a object_path=unknown" do
            before do
              organization.extended_data.update(data: { "personal" => { "birthday" => "1989-01-28" } })
            end

            let!(:object_path) { "unknown" }

            run_test!(example_name: :not_found)
          end
        end
      end
    end
  end
end
