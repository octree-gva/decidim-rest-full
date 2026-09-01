# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::ApartmentTenantSwitch do
  describe ".call" do
    it "yields without switching when ros-apartment is not the branch" do
      skip "ros-apartment loaded" if Gem.loaded_specs.has_key?("ros-apartment")

      expect(described_class.call("example.org") { :ok }).to eq(:ok)
    end

    it "does not yield for an unknown host when ros-apartment is loaded" do
      skip "ros-apartment not in bundle" unless Gem.loaded_specs.has_key?("ros-apartment")

      expect(described_class.call("missing-tenant.example.org") { :leaked }).to be_nil
    end

    it "does not prepend CurrentOrganizationApartment" do
      skip "ros-apartment not in bundle" unless Gem.loaded_specs.has_key?("ros-apartment")

      names = Decidim::Middleware::CurrentOrganization.ancestors.map(&:name)
      expect(names).not_to include("Decidim::RestFull::Core::CurrentOrganizationApartment")
    end
  end
end
