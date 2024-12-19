# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::OAuth::UsersController", type: :request do
  path "/system/users/{user_id}/extended_data" do
    get "Get All user extended data" do
      tags "System"
      produces "application/json"
      security [{ credentialFlowBearer: ["system"] }]
      operationId "userDataRoot"
      description "Fetch user extended data"
      parameter name: "user_id", in: :path, schema: { type: :integer, description: "User Id" }

      let!(:organization) { create(:organization) }
      let(:api_client) do
        api_client = create(:api_client, organization: organization, scopes: "system")
        api_client.permissions = [
          api_client.permissions.build(permission: "system.users.extended_data.read")
        ]
        api_client.save!
        api_client
      end

      let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "custom" => { "data" => { key: "value" } } }) }
      let!(:credential_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }
      let(:Authorization) { "Bearer #{credential_token.token}" }

      let!(:user_id) { user.id }

      before do
        host! organization.host
      end

      response "200", "Extended data fetched" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/user_extended_data"
        context "with extended_data={'foo' => {'bar' => 'true'}}, returns the object" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "foo" => { "bar" => "true" } }) }

          run_test!(:ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(response.status).to eq(200)
            expect(data).to eq({ "foo" => { "bar" => "true" } })
          end
        end
      end
    end
  end

  path "/system/users/{user_id}/extended_data/{path}" do
    get "Get user extended data" do
      tags "System"
      produces "application/json"
      security [{ credentialFlowBearer: ["system"] }]
      operationId "userData"
      description "Fetch user extended data"
      parameter name: "user_id", in: :path, schema: { type: :integer, description: "User Id" }
      parameter name: "path", in: :path, schema: { type: :string, description: "object path, in path style, like foo/bar to access foo.bar" }

      let!(:organization) { create(:organization) }
      let(:api_client) do
        api_client = create(:api_client, organization: organization, scopes: "system")
        api_client.permissions = [
          api_client.permissions.build(permission: "system.users.extended_data.read")
        ]
        api_client.save!
        api_client
      end

      let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "custom" => { "data" => { key: "value" } } }) }
      let!(:credential_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }
      let(:Authorization) { "Bearer #{credential_token.token}" }

      let!(:user_id) { user.id }
      let!(:path) { "custom/data" }

      before do
        host! organization.host
      end

      response "200", "Extended Data for a given path given" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/user_extended_data"
        context "with extended_data={'foo' => {'bar' => 'true'}}, can access path=foo/bar" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "foo" => { "bar" => "true" } }) }
          let!(:path) { "foo/bar" }

          run_test! do |example|
            data = JSON.parse(example.body)["data"]
            expect(response.status).to eq(200)
            expect(data).to eq("true")
          end
        end

        context "with extended_data={'personal' => {'birthday' => '1989-01-28'}}, can access path=personal" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
          let!(:path) { "personal" }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(response.status).to eq(200)
            expect(data).to include({ "birthday" => "1989-01-28" })
          end
        end

        context "with extended_data=<whatever object>, can access path=/" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
          let!(:path) { "" }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(response.status).to eq(200)
            expect(data).to include({ "personal" => { "birthday" => "1989-01-28" } })
          end
        end
      end

      response "404", "Not Found" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with a path=unknown" do
          let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
          let!(:path) { "unknown" }

          run_test!(example_name: :not_found)
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with no system scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["blogs"]) }
          let!(:credential_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no system.users.extended_data.read permission" do
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
