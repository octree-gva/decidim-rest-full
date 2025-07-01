# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Organizations::OrganizationExtendedDataController do
  path "/organizations/{id}/extended_data" do
    put "Update organization extended data" do
      tags "Organizations Extended Data"
      produces "application/json"
      operationId "setOrganizationExtendedData"
      description <<~README
        The extended_data feature allows you to update a hash with recursive merging. Use the body payload with these keys:

        1. `data`: The value or hash you want to update.
        2. `object_path`: The dot-style path to the key (e.g., access.this.key).

        **Root path**<br />
        To update data from root of the hash, use `object_path="."`.

        Example:
        ```
          body={"data": {"name": "Jane"}, "object_path": "personnal"}
        ```
        This recursively merges data into the hash without removing existing keys.

        **Merge some data**<br />
        Initial hash:
        ```json
          {
            "personnal": {"birthday": "1989-05-18"}
          }
        ```
        Patch payload:
        ```json
          {
            "data": {
              "name": "Jane"
            },
            "object_path": "personnal"
          }
        ```
        Result:
        ```
          {
            "personnal": {"birthday": "1989-05-18", "name": "Jane"}
          }
        ```

        **Create new Paths**<br />
        Paths are created as needed.
        Exemple:
        ```json
          body = {"data": {"external_user_id": 12}, "object_path": "data-store.my-app.foo"}
        ```
        Result:
        ```json
          {
            "personnal": {"birthday": "1989-05-18"},
            "data-store": {"my-app": {"foo": {"external_user_id": 12}}}
          }
        ```
        Alternatively:
        ```
          body = {"data": 12, "object_path": "data-store.my-app.foo.external_user_id"}
        ```

        **Remove a key**<br />
        Set a key to null or an empty value to remove it.

        Example: Initial hash:
        ```json
          {
            "personnal": {"birthday": "1989-05-18", "name": "Jane"}
          }
        ```
        Patch:
        ```json
          body = {"data": {"birthday": ""}, "object_path": "personnal"}
        ```

        Result:
        ```
        {
          "personnal": {"name": "Jane"}
        }
        ```

        **Return Value**<br />
        The update request returns the updated value at the specified path.

      README
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        title: "User Extended Data Payload",
        properties: {
          data: { type: :object, title: "User Extended Data Data", description: "New value for the extended data at the given path" },
          object_path: { type: :string, description: "object path, in dot style, like foo.bar. use '.' to update the whole user data" }
        }, required: [:data]
      }
      parameter name: "id", in: :path, schema: { type: :integer, description: "Id of the organization" }
      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Organizations::OrganizationExtendedDataController,
        action: :update,
        security_types: [:credentialFlow],
        scopes: ["system"],
        permissions: ["system.organization.extended_data.update"]
      ) do
        let(:body) { { data: { "foo" => "bar" }, object_path: "." } }
        let(:organization) { create(:organization) }
        let(:id) { organization.id }

        response "200", "Update extended data value" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:organization_extended_data)

          context "with root path '.'" do
            before do
              organization.extended_data.update(data: { "foo" => { "bar" => "true" } })
            end

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to eq(body[:data])
            end
          end

          context "with a path given" do
            before do
              organization.extended_data.update(data: { "personal" => { "birthday" => "1989-01-28" } })
            end

            let(:body) { { data: "1990-02-09", object_path: "personal.birthday" } }

            run_test! do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include("1990-02-09")
            end
          end

          context "with a path given and merging data" do
            before do
              organization.extended_data.update(data: { "personal" => { "birthday" => "1989-01-28" } })
            end

            let(:body) { { data: { "name" => "Jeanne" }, object_path: "personal" } }

            run_test! do |example|
              JSON.parse(example.body)["data"]
              organization.reload
              expect(response).to have_http_status(:ok)
              expect(organization.extended_data.data["personal"]).to include({ "name" => "Jeanne", "birthday" => "1989-01-28" })
            end
          end

          context "with a path given and unsetting data" do
            before do
              organization.extended_data.update(data: { "personal" => { "birthday" => "1989-01-28", "name" => "Jeanne" } })
            end

            let(:body) { { data: { "name" => nil }, object_path: "personal" } }

            run_test! do |example|
              JSON.parse(example.body)["data"]
              organization.reload
              expect(response).to have_http_status(:ok)
              expect(organization.extended_data.data["personal"].keys).to eq(["birthday"])
            end
          end

          context "with a path=unknown, upsert" do
            before do
              organization.extended_data.update(data: { "personal" => { "birthday" => "1989-01-28" } })
            end

            let(:body) { { data: { "whatever" => { "is" => { "stil" => "ok" } } }, object_path: "unknown" } }

            run_test! do |example|
              organization.reload
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include(body[:data])
              expect(organization.extended_data.data).to eq({
                                                              "personal" => { "birthday" => "1989-01-28" },
                                                              "unknown" => { "whatever" => { "is" => { "stil" => "ok" } } }
                                                            })
            end
          end
        end
      end
    end
  end
end
