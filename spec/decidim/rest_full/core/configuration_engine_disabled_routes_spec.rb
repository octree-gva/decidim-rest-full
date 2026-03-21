# frozen_string_literal: true

require "spec_helper"

# When enable_proposals_api / enable_blogs_api is false, route constraints return 404
# (see lib/decidim/rest_full/proposals/engine.rb and blogs/engine.rb).
RSpec.describe Decidim::RestFull::Core::Configuration, type: :request do
  let(:organization) { create(:organization, host: "test.example.org") }

  before do
    host!(organization.host)
  end

  describe "proposals" do
    around do |example|
      prev = Decidim::RestFull::Core::Configuration.enable_proposals_api
      Decidim::RestFull::Core::Configuration.enable_proposals_api = false
      example.run
      Decidim::RestFull::Core::Configuration.enable_proposals_api = prev
    end

    it "does not register proposals routes when disabled" do
      expect do
        get "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/proposals"
      end.to raise_error(ActionController::RoutingError, /No route matches/)
    end
  end

  describe "blogs" do
    around do |example|
      prev = Decidim::RestFull::Core::Configuration.enable_blogs_api
      Decidim::RestFull::Core::Configuration.enable_blogs_api = false
      example.run
      Decidim::RestFull::Core::Configuration.enable_blogs_api = prev
    end

    it "does not register blogs routes when disabled" do
      expect do
        get "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/blogs"
      end.to raise_error(ActionController::RoutingError, /No route matches/)
    end
  end
end
