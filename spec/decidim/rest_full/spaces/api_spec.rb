# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe Decidim::RestFull::System::API do
  include Rack::Test::Methods
  let!(:organization_a) { create(:organization) }
  let!(:organization_b) { create(:organization) }
  let!(:organization) { create(:organization) }

  def app
    Decidim::RestFull::System::API
  end

  def credential_token(scope = "spaces")
    api_client = create(:api_client, scopes: scope, organization: organization)
    access_token = api_client.access_tokens.create(scopes: scope)
    access_token.token
  end

  describe "GET /spaces/spaces" do
    it "requires a spaces scope" do 
      get "/spaces/spaces", {}, "HTTP_AUTHORIZATION" => "Bearer #{credential_token("public")}"
      expect(last_response).to have_http_status(:forbidden)
      get "/spaces/spaces", {}, "HTTP_AUTHORIZATION" => "Bearer #{credential_token("proposals")}"
      expect(last_response).to have_http_status(:forbidden)
    end
    it "returns space ids" do
      get "/spaces/spaces", {}, "HTTP_AUTHORIZATION" => "Bearer #{credential_token}"
      expect(last_response).to have_http_status(:ok)
      expect(last_response.headers["Content-Type"]).to eq("application/json")
      expect(JSON.parse(last_response.body)["organizations"]).to include(
        { "id" => organization_a.id }
      )
    end

    describe "?populate[title]=1" do
      it "returns organizations ids and titles, in all locales" do
        get "/spaces/spaces", {"populate[title]" => 1}, "HTTP_AUTHORIZATION" => "Bearer #{credential_token}"
        expect(last_response).to have_http_status(:ok)
        expect(last_response.headers["Content-Type"]).to eq("application/json")
        expect(JSON.parse(last_response.body)["organizations"]).to include(
          { "id" => organization_a.id, "title" => organization_a.name }
        )
      end

      describe "&locales[]=fr" do
        it "returns organizations ids and names, only in french" do
          get "/spaces/spaces", {"populate[name]" => 1, "locales[]" => "fr"}, "HTTP_AUTHORIZATION" => "Bearer #{credential_token}"
          expect(last_response).to have_http_status(:ok)
          expect(last_response.headers["Content-Type"]).to eq("application/json")
          expect(JSON.parse(last_response.body)["organizations"]).to include(
            { "id" => organization_a.id, "name" => { "fr" => organization_a.name["fr"] } }
          )
        end
      end
    end
  end
end
