# frozen_string_literal: true

# spec/integration/oauth_scopes_spec.rb
require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::System::ApplicationController", type: :request do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization, password: "decidim123456789!", password_confirmation: "decidim123456789!") }
  let!(:api_client) { create(:api_client, organization: organization) }

  before do
    host! api_client.organization.host
  end

  path "/oauth/token" do
    post "Request a OAuth token through Client Credentials" do
      tags "OAuth"
      consumes "application/json"
      produces "application/json"
      security([])
      parameter name: :body, in: :body, required: true, schema: { "$ref" => "#/components/schemas/oauth_grant_param" }

      response "200", "Token returned" do
        context "with client_credentials grant" do
          let(:system_api_client) { create(:api_client, organization: organization, scopes: "system") }
          let(:body) do
            {
              grant_type: "client_credentials",
              auth_type: "impersonate",
              client_id: system_api_client.client_id,
              client_secret: system_api_client.client_secret,
              scope: "system"
            }
          end

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["access_token"]).to be_present
            expect(
              Doorkeeper::AccessToken.find_by(token: json_response["access_token"]).scopes
            ).to include("system")
          end
        end
      end
    end
  end
end
