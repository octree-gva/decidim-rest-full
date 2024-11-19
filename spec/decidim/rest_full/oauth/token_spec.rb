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
    post "Request a OAuth token" do
      tags "OAuth"
      consumes "application/json"
      produces "application/json"
      security([])
      parameter name: :body, in: :body, required: true, schema: { "$ref" => "#/components/schemas/oauth_grant_param" }

      response "200", "Token returned" do
        context "with grant=password auth_type=impersonate" do
          let(:body) do
            {
              grant_type: "password",
              auth_type: "impersonate",
              username: user.nickname,
              client_id: api_client.client_id,
              client_secret: api_client.client_secret,
              scope: "public"
            }
          end

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["access_token"]).to be_present
            expect(
              Doorkeeper::AccessToken.find_by(token: json_response["access_token"]).scopes
            ).to include("public")
          end
        end

        context "with grant=password auth_type=login" do
          let(:proposal_api_client) { create(:api_client, organization: organization, scopes: "proposals public") }

          let(:body) do
            {
              grant_type: "password",
              auth_type: "login",
              password: "decidim123456789!",
              username: user.nickname,
              client_id: proposal_api_client.client_id,
              client_secret: proposal_api_client.client_secret,
              scope: "public proposals"
            }
          end

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["access_token"]).to be_present
            expect(
              Doorkeeper::AccessToken.find_by(token: json_response["access_token"]).scopes
            ).to include("proposals")
          end
        end

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

      response "400", "Bad Request" do
        context "with client_id from another organization" do
          let(:foreign_api_client) { create(:api_client) }
          let(:body) do
            {
              grant_type: "password",
              username: user.nickname,
              auth_type: "impersonate",
              client_id: foreign_api_client.client_id,
              client_secret: foreign_api_client.client_secret,
              scope: "public"
            }
          end

          before { host! foreign_api_client.organization.host }

          run_test!
        end

        context "with impersonate username from an another tenant" do
          let(:other_tenant) { create(:organization) }
          let(:body) do
            {
              grant_type: "password",
              username: user.nickname,
              auth_type: "impersonate",
              client_id: api_client.client_id,
              client_secret: api_client.client_secret,
              scope: "public"
            }
          end

          before { host! other_tenant.host }

          run_test!
        end

        context "with scope=system and password grant" do
          let(:system_api_client) { create(:api_client, organization: organization, scopes: "system") }
          let(:body) do
            {
              grant_type: "password",
              username: user.nickname,
              auth_type: "impersonate",
              client_id: system_api_client.client_id,
              client_secret: system_api_client.client_secret,
              scope: "system"
            }
          end

          run_test!
        end
      end
    end
  end
end
