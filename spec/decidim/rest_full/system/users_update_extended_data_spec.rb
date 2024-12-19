# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::OAuth::UsersController", type: :request do
  path "/system/users/{user_id}/extended_data/{path}" do
    put "Update user extended data" do
      tags "System"
      produces "application/json"
      security [{ credentialFlowBearer: ["system"] }]
      operationId "setUserData"
      description <<~README

        **Update all the data**<br />
        To update all the extended_data of a user, use `path="/"` or `path=""`.

        **Merge some data**<br />
        The update operation here is a __merge__. For example, given:
        ```json
          {
            "personnal": {"birthday": "1989-05-18"}
          }
        ```
        if you patch `path="personnal"`, `body={"data": {"name": "Jane"}}`, you will get:
        ```json
          {
            "personnal": {"birthday": "1989-05-18", "name": "Jane"}
          }
        ```

        **Create new Paths**<br />
        To make things easy, paths are already created. For example, given:
        ```json
          {
            "personnal": {"birthday": "1989-05-18"}
          }
        ```
        if you patch `path="data-store/my-app/foo"`, `body={"data": {"external_user_id": "12"}}`, you will get:
        ```json
          {
            "personnal": {"birthday": "1989-05-18", "name": "Jane"},
            "data-store": {"my-app": {"foo": {"external_user_id": 12}}}
          }
        ```
        Or you can also set `path="data-store/my-app/foo/external_user_id"`, `body={"data": 12}` for the same result

        **Remove a key**<br />
        To remove a key of a user extended_data, you need to set its value to a null or empty one.
        ```json
          {
            "personnal": {"birthday": "1989-05-18", "name": "Jane"}
          }
        ```
        Given this data, if you set `path="personnal/birthday"` and `body={"data": {"birthday": ""}}`, the key will be removed.
        Same if you do `path="/"` and `body={"data": {"personal": {"birthday": null}}}`, the result will be:
        ```json
          {
            "personnal": {"name": "Jane"}
          }
        ```

        **Return value**<br />
        Update request gives back the actual value at the given path.#{" "}

      README

      parameter name: :user_id, in: :path, schema: { type: :integer, description: "User Id" }
      parameter name: :path, in: :path, required: false, schema: { type: :string, description: "object path, in path style, like foo/bar to access foo.bar. use empty string or '/' to update the whole user data" }
      parameter name: :body, in: :body, required: true, schema: { type: :object, properties: { data: { type: :object, description: "New value for the extended data at the given path" } }, required: [:data] }

      let!(:organization) { create(:organization) }
      let(:api_client) do
        api_client = create(:api_client, organization: organization, scopes: "system")
        api_client.permissions = [
          api_client.permissions.build(permission: "system.users.extended_data.update")
        ]
        api_client.save!
        api_client
      end

      let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "custom" => { "data" => { key: "value" } } }) }
      let!(:credential_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }
      let(:Authorization) { "Bearer #{credential_token.token}" }

      let!(:user_id) { user.id }
      let!(:path) { "" }
      let!(:body) { { data: { "foo" => "bar" } } }

      before do
        host! organization.host
      end

      response "200", "Update extended data value" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/user_extended_data"

        context "with a empty path" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "foo" => { "bar" => "true" } }) }
          let!(:path) { "" }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(response.status).to eq(200)
            expect(data).to eq(body[:data])
          end
        end

        context "with a path given" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
          let!(:path) { "personal/birthday" }
          let!(:body) { { data: "1990-02-09" } }

          run_test! do |example|
            data = JSON.parse(example.body)["data"]
            expect(response.status).to eq(200)
            expect(data).to include("1990-02-09")
          end
        end

        context "with a path given and merging data" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
          let!(:path) { "personal" }
          let!(:body) { { data: { "name" => "Jeanne" } } }

          run_test! do |example|
            JSON.parse(example.body)["data"]
            user.reload
            expect(response.status).to eq(200)
            expect(user.extended_data["personal"]).to include({ "name" => "Jeanne", "birthday" => "1989-01-28" })
          end
        end

        context "with a path given and unsetting data" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28", "name" => "Jeanne" } }) }
          let!(:path) { "personal" }
          let!(:body) { { data: { "name" => nil } } }

          run_test! do |example|
            JSON.parse(example.body)["data"]
            user.reload
            expect(response.status).to eq(200)
            expect(user.extended_data["personal"].keys).to eq(["birthday"])
          end
        end

        context "with a path=unknown, upsert" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
          let!(:path) { "unknown" }
          let!(:body) { { data: { "whatever" => { "is" => { "stil" => "ok" } } } } }

          run_test! do |example|
            user.reload
            data = JSON.parse(example.body)["data"]
            expect(response.status).to eq(200)
            expect(data).to include(body[:data])
            expect(user.extended_data).to eq({
                                               "personal" => { "birthday" => "1989-01-28" },
                                               "unknown" => { "whatever" => { "is" => { "stil" => "ok" } } }
                                             })
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"
        let!(:path) { "" }
        let!(:body) { { data: "1990-02-09" } }

        context "with no system scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["blogs"]) }
          let!(:credential_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no system.users.extended_data.update permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:credential_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"
        let!(:path) { "" }
        let!(:body) { { data: "1990-02-09" } }

        before do
          controller = Decidim::Api::RestFull::System::UserExtendedDataController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::System::UserExtendedDataController).to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
