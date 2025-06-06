# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::ApplicationController do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization, password: "decidim123456789!", password_confirmation: "decidim123456789!") }
  let!(:api_client) { create(:api_client, organization: organization, scopes: "public") }
  let!(:permissions) do
    api_client.permissions = [
      api_client.permissions.build(permission: "oauth.impersonate"),
      api_client.permissions.build(permission: "oauth.login")
    ]
    api_client.save!
  end
  let!(:client_credential_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
  let!(:bearer_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: user.id, application: api_client) }

  before do
    host! api_client.organization.host
  end

  path "/oauth/introspect" do
    post "Introspect a OAuth token" do
      tags "OAuth"
      consumes "application/json"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "introspectToken"
      description "Get given oauth token details"
      # SEE https://datatracker.ietf.org/doc/html/rfc7662#section-2.1
      parameter name: :body, in: :body, required: true, schema: { type: :object, properties: { token: { type: :string } }, required: [:token] }

      response "200", "User details returned" do
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:introspect_data)
        context "with client_credentials grant" do
          let!(:client_credential_token_b) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

          let(:Authorization) { "Bearer #{client_credential_token.token}" }
          let(:body) { { token: client_credential_token_b.token } }

          run_test!(example_name: :bearer_client_credential) do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["scope"]).to include("public")
          end
        end

        context "with password grant" do
          let(:Authorization) { "Bearer #{client_credential_token.token}" }
          let(:body) { { token: bearer_token.token } }

          run_test!(example_name: :bearer_ropc) do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["resource"]["id"]).to eq(user.id.to_s)
            expect(json_response["resource"]["type"]).to eq("user")
            expect(json_response["scope"]).to include("public")
          end
        end
      end

      response "401", "When the token is invalid" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with expired token" do
          let!(:client_credential_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client, created_at: 1.month.ago, expires_in: 1.minute) }

          let(:Authorization) { "Bearer #{client_credential_token.token}" }
          let(:body) { { token: client_credential_token.token } }

          run_test!(example_name: :expired_token)
        end
      end
    end
  end
end
