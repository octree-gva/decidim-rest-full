# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe Decidim::RestFull::System::API do
  include Rack::Test::Methods
  let!(:organization_a) { create(:organization) }
  let!(:organization_b) { create(:organization) }

  def app
    Decidim::RestFull::System::API
  end

  describe "GET /system/organizations" do
    it "returns organizations ids" do
      get "/system/organizations"
      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("application/json")
      expect(JSON.parse(last_response.body)).to eq("organizations" => [{ "id" => organization_a.id }, { "id" => organization_b.id }])
    end

    describe "?populate[name]=1" do
      it "returns organizations ids and names, in all locales" do
        get "/system/organizations?populate[name]=1"
        expect(last_response.status).to eq(200)
        expect(last_response.headers["Content-Type"]).to eq("application/json")
        expect(JSON.parse(last_response.body)).to eq("organizations" => [
                                                       { "id" => organization_a.id, "name" => organization_a.name },
                                                       { "id" => organization_b.id, "name" => organization_b.name }
                                                     ])
      end

      describe "&locales[]=fr" do
        it "returns organizations ids and names, only in french" do
          get "/system/organizations?populate[name]=1&locales[]=fr"
          expect(last_response.status).to eq(200)
          expect(last_response.headers["Content-Type"]).to eq("application/json")
          expect(JSON.parse(last_response.body)).to eq("organizations" => [
                                                         { "id" => organization_a.id, "name" => { "fr" => organization_a.name["fr"] } },
                                                         { "id" => organization_b.id, "name" => { "fr" => organization_b.name["fr"] } }
                                                       ])
        end
      end
    end
  end
end
