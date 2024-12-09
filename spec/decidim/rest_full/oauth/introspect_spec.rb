# frozen_string_literal: true

# spec/integration/oauth_scopes_spec.rb
require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::System::ApplicationController", type: :request do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization, password: "decidim123456789!", password_confirmation: "decidim123456789!") }
  let!(:api_client) { create(:api_client, organization: organization) }
  let!(:permissions) do
    api_client.permissions = [
      api_client.permissions.build(permission: "oauth.impersonate"),
      api_client.permissions.build(permission: "oauth.login")
    ]
    api_client.save!
  end
  let!(:client_credential_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
  let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: user.id, application: api_client) }

  before do
    host! api_client.organization.host
  end

  path "/oauth/introspect" do
    post "Introspect a OAuth token" do
      tags "OAuth"
      consumes "application/json"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]

      response "200", "User details returned" do
        schema "$ref" => "#/components/schemas/introspect_response"
        context "with client_credentials grant" do
          let(:Authorization) { "Bearer #{client_credential_token.token}" }

          run_test!(example_name: :bearer_client_credential) do |response|
            json_response = JSON.parse(response.body)["data"]
            expect(json_response["token"]["scope"]).to include("public")
          end
        end

        context "with password grant" do
          let(:Authorization) { "Bearer #{impersonation_token.token}" }

          run_test!(example_name: :bearer_ropc) do |response|
            json_response = JSON.parse(response.body)["data"]
            expect(json_response["resource"]["id"]).to eq(user.id.to_s)
            expect(json_response["resource"]["type"]).to eq("user")
            expect(json_response["token"]["scope"]).to include("public")
          end
        end
      end

      response "200", "When the token is invalid" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/introspect_response"

        context "with expired token" do
          let!(:client_credential_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client, created_at: 1.month.ago, expires_in: 1.minute) }

          let(:Authorization) { "Bearer #{client_credential_token.token}" }

          run_test!(example_name: :expired_token) do |response|
            json_response = JSON.parse(response.body)["data"]
            expect(json_response["active"]).to be_falsy
          end
        end
      end
    end
  end
end
