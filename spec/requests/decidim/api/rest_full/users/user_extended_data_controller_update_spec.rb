# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::UserExtendedDataController do
  path "/me/extended_data" do
    put "Update user extended data" do
      tags "Users"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["oauth"] }]
      operationId "setUserData"
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
        properties: {
          data: { type: :object, description: "New value for the extended data at the given path" },
          object_path: { type: :string, description: "object path, in dot style, like foo.bar. use '.' to update the whole user data" }
        }, required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Users::UserExtendedDataController,
        action: :update,
        security_types: [:impersonationFlow],
        scopes: ["oauth"],
        permissions: ["oauth.extended_data.update"]
      ) do
        let(:body) { { data: { "foo" => "bar" }, object_path: "." } }

        response "200", "Update extended data value" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:user_extended_data)

          context "with root path '.'" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "foo" => { "bar" => "true" } }) }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to eq(body[:data])
            end
          end

          context "with a path given" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
            let(:body) { { data: "1990-02-09", object_path: "personal.birthday" } }

            run_test! do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include("1990-02-09")
            end
          end

          context "with a path given and merging data" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
            let(:body) { { data: { "name" => "Jeanne" }, object_path: "personal" } }

            run_test! do |example|
              JSON.parse(example.body)["data"]
              user.reload
              expect(response).to have_http_status(:ok)
              expect(user.extended_data["personal"]).to include({ "name" => "Jeanne", "birthday" => "1989-01-28" })
            end
          end

          context "with a path given and unsetting data" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28", "name" => "Jeanne" } }) }
            let(:body) { { data: { "name" => nil }, object_path: "personal" } }

            run_test! do |example|
              JSON.parse(example.body)["data"]
              user.reload
              expect(response).to have_http_status(:ok)
              expect(user.extended_data["personal"].keys).to eq(["birthday"])
            end
          end

          context "with a path=unknown, upsert" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
            let(:body) { { data: { "whatever" => { "is" => { "stil" => "ok" } } }, object_path: "unknown" } }

            run_test! do |example|
              user.reload
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include(body[:data])
              expect(user.extended_data).to eq({
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
