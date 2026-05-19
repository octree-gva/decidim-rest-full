# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass, -- cross-cutting optional-gem integration
RSpec.describe "optional decidim-restfull feature gems" do
  describe Decidim::RestFull::Core::Ransackers do
    it "registers core ransackers without decidim-proposals loaded" do
      expect { described_class.register_ransackers! }.not_to raise_error
    end
  end

  describe Decidim::Api::RestFull::Core::SerializerLookup do
    it "falls back to core ComponentSerializer when the adapter gem is absent" do
      allow(described_class).to receive(:safe_constant_defined?).and_return(false)
      expect(described_class.component_serializer_class_for("proposals")).to eq(
        Decidim::Api::RestFull::Core::ComponentSerializer
      )
    end

    it "resolves meetings serializer when decidim-restfull-meetings is loaded" do
      skip "decidim-restfull-meetings not in bundle" unless defined?(Decidim::Api::RestFull::Meetings::MeetingComponentSerializer)

      expect(described_class.component_serializer_class_for("meetings")).to eq(
        Decidim::Api::RestFull::Meetings::MeetingComponentSerializer
      )
    end

    it "resolves page serializer from core without a feature gem" do
      expect(described_class.component_serializer_class_for("pages")).to eq(
        Decidim::Api::RestFull::Core::PageComponentSerializer
      )
    end
  end

  describe Decidim::RestFull::Core::Ability do
    let(:organization) { create(:organization) }
    let(:api_client) do
      create(:api_client, organization:, scopes: %w(meetings)).tap do |client|
        client.permissions.create!(permission: "meetings.read")
      end
    end

    it "does not reference proposals when only meetings scope is used" do
      ability = described_class.new(api_client)
      skip "decidim-meetings not in bundle" unless defined?(Decidim::Meetings::Meeting)

      expect(ability.can?(:read, Decidim::Meetings::Meeting)).to be(true)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
