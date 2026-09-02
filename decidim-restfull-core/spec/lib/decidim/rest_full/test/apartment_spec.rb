# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim::RestFull::Test::ApartmentOrg" do
  describe ".provision!" do
    it "creates a second tenant for a different host" do
      skip "ros-apartment not in bundle" unless Gem.loaded_specs.has_key?("ros-apartment")

      org_a = create(:organization, host: "tenant-a.example.org", available_locales: ["en"])
      org_b = create(:organization, host: "tenant-b.example.org", available_locales: ["en"])

      expect(Decidim::Apartment::DistributionKey.for_host(org_a.host)).to be_present
      expect(Decidim::Apartment::DistributionKey.for_host(org_b.host)).to be_present
    end
  end
end
