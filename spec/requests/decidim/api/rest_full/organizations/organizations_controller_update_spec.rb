# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Organizations::OrganizationsController do
  path "/organizations/{id}" do
    put "Update organization" do
      tags "Organizations"
      produces "application/json"
      operationId "updateOrganization"
      description <<~README
        This endpoint allows you to update an organization.

        ### Update host
        To update the host, send in your payload the `host` attribute. It will be saved as an `unconfirmed_host` extended data attribute.#{" "}
        Once saved, a job will be enqueued to reverse DNS the unconfirmed host before actually updating the host.
        The `host` attribute must be unique across all organizations.
        More information on this update process is documented in the [Safe host update](#{Decidim::RestFull.config.docs_url}/dev/update-hosts) page.

        ### Update name
        To update the name, send in your payload the `name` attribute.
        The `name` attribute must be unique across all organizations.
      README
      parameter name: :id, in: :path, type: :string, required: true, description: "The ID of the organization"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        title: "Update Organization Payload",
        properties: {
          data: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:organization_attributes)
          }
        }, required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Organizations::OrganizationsController,
        action: :update,
        security_types: [:credentialFlow],
        scopes: ["system"],
        permissions: ["system.organizations.update"]
      ) do
        let(:organization) { create(:organization) }
        let(:id) { organization.id }

        response "200", "Organization updated" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:organization_item_response)

          context "with new name in one locale" do
            let(:organization) { create(:organization, available_locales: %w(en fr), default_locale: "en", name: { "en" => "Organization Name", "fr" => "Nom de l'organisation" }) }
            let(:body) { { data: { name: { "en" => "New Name" } } } }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data["attributes"]["name"]["en"]).to eq("New Name")
              expect(data["attributes"]["name"]["fr"]).to eq("Nom de l'organisation")
            end
          end

          context "when update host, unconfirmed host is set" do
            let(:organization) { create(:organization) }
            let(:body) { { data: { host: "new-host.com" } } }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data["meta"]["unconfirmed_host"]).to eq("new-host.com")
              expect(data["attributes"]["host"]).to eq(organization.host)
              expect(data["attributes"]["host"]).not_to eq("new-host.com")
            end
          end
        end

        response "400", "Organization Bad Request" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          let!(:organization2) { create(:organization, name: { "en" => "Existing Organization Name", "fr" => "Nom de l'organisation" }) }
          let(:body) { { data: { name: { "en" => "Existing Organization Name" } } } }

          context "when name is already taken" do
            run_test!(example_name: :bad_request_name_taken) do |example|
              data = JSON.parse(example.body)
              expect(response).to have_http_status(:bad_request)
              expect(data["error_description"]).to include("Name en has already been taken")
            end
          end

          context "when host is already taken" do
            let(:body) { { data: { host: organization2.host } } }

            run_test!(example_name: :bad_request_host_taken) do |example|
              data = JSON.parse(example.body)
              expect(response).to have_http_status(:bad_request)
              expect(data["error_description"]).to include("Unconfirmed host has already been taken")
            end
          end
        end

        response "404", "Organization Not Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          let(:body) { { data: { name: { "en" => "New Name" } } } }

          context "when id=bad_string" do
            let(:id) { "bad_string" }

            run_test!(example_name: :not_found)
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
