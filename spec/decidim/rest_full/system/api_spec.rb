# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe Decidim::RestFull::System::API do
  include Rack::Test::Methods

  def app
    Decidim::RestFull::System::API
  end

  describe "GET /system/statuses/public_timeline" do
    it "returns the public timeline" do
      get "/system/organization"
      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("application/json")
      expect(JSON.parse(last_response.body)).to eq("organization" => {"id": 1})
    end
  end
end
