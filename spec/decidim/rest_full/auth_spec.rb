# frozen_string_literal: true

require "spec_helper"
RSpec.describe "OAuth Scopes", type: :request do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization) }

  let!(:api_client) { create(:api_client, organization: organization) }

  before do
    host! api_client.organization.host
  end

  describe "Resource Owner Password Credential Flow" do
    it "200 OK: Returns a token with requested scopes" do
      post "/oauth/token", params: {
        grant_type: "password",
        username: user.nickname,
        client_id: api_client.client_id,
        client_secret: api_client.client_secret,
        scope: "public"
      }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["access_token"]).to be_present
      expect(Doorkeeper::AccessToken.find_by(token: body["access_token"]).scopes).to exist("public")
    end

    it "400 bad request: Request a user from another organization" do
      foreign_api_client = create(:api_client)
      host! foreign_api_client.organization.host

      post "/oauth/token", params: {
        grant_type: "password",
        username: user.nickname,
        client_id: foreign_api_client.client_id,
        client_secret: foreign_api_client.client_secret,
        scope: "public"
      }

      expect(response).to have_http_status(:bad_request)
    end

    it "400 bad request: Request a token to an another organization tenant." do
      other_tenant = create(:organization)
      host! other_tenant.host

      post "/oauth/token", params: {
        grant_type: "password",
        username: user.nickname,
        client_id: api_client.client_id,
        client_secret: api_client.client_secret,
        scope: "public"
      }

      expect(response).to have_http_status(:bad_request)
    end

    it "400 bad request: can not ask for system scope" do
      system_api_client = create(:api_client, organization: organization, scopes: "system")
      post "/oauth/token", params: {
        grant_type: "password",
        username: user.nickname,
        client_id: system_api_client.client_id,
        client_secret: system_api_client.client_secret,
        scope: "system"
      }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "Client Credential Flow" do
    it "200 ok: can request for a system scope" do
      system_api_client = create(:api_client, organization: organization, scopes: "system")
      post "/oauth/token", params: {
        grant_type: "client_credentials",
        client_id: system_api_client.client_id,
        client_secret: system_api_client.client_secret,
        scope: "system"
      }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["access_token"]).to be_present
      expect(Doorkeeper::AccessToken.find_by(token: body["access_token"]).scopes).to exist("system")
    end
  end
end
