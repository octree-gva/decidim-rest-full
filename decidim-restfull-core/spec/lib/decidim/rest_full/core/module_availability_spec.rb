# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::ModuleAvailability do
  subject { described_class }

  let(:organization) { create(:organization) }

  def stub_config(hash)
    allow(described_class).to receive(:raw_config).with(organization).and_return(hash.with_indifferent_access)
  end

  describe ".enabled?" do
    it "defaults to true when no Toggle row" do
      stub_config({})
      expect(subject.enabled?(organization)).to be(true)
    end

    it "is false when master enabled is false" do
      stub_config(enabled: false)
      expect(subject.enabled?(organization)).to be(false)
    end
  end

  describe ".module_enabled?" do
    it "defaults feature modules to true when master is on and key missing" do
      stub_config(enabled: true)
      expect(subject.module_enabled?(organization, :blogs)).to be(true)
    end

    it "is false when master is off even if feature is true" do
      stub_config(enabled: false, blogs_enabled: true)
      expect(subject.module_enabled?(organization, :blogs)).to be(false)
    end

    it "is false when feature flag is off" do
      stub_config(enabled: true, blogs_enabled: false)
      expect(subject.module_enabled?(organization, :blogs)).to be(false)
    end

    it "is false when the feature gem is not installed" do
      stub_config(enabled: true, proposals_enabled: true)
      allow(Decidim::Toggle).to receive(:gem_present?).with("decidim-restfull-proposals").and_return(false)
      expect(subject.module_enabled?(organization, :proposals)).to be(false)
    end
  end

  describe ".feature_gem_present?" do
    it "treats attachments as always present (core)" do
      expect(subject.feature_gem_present?(:attachments)).to be(true)
    end

    it "delegates to Decidim::Toggle.gem_present? for feature gems" do
      allow(Decidim::Toggle).to receive(:gem_present?).with("decidim-restfull-blogs").and_return(false)
      expect(subject.feature_gem_present?(:blogs)).to be(false)
    end
  end

  describe ".available_feature_modules" do
    it "omits features whose gem is absent" do
      allow(subject).to receive(:feature_gem_present?).and_return(true)
      allow(subject).to receive(:feature_gem_present?).with(:proposals).and_return(false)

      expect(subject.available_feature_modules).not_to include(:proposals)
      expect(subject.available_feature_modules).to include(:attachments)
    end
  end

  describe ".scope_enabled?" do
    it "hides all scopes when master is off" do
      stub_config(enabled: false)
      expect(subject.scope_enabled?(organization, :public)).to be(false)
      expect(subject.scope_enabled?(organization, :blogs)).to be(false)
    end

    it "keeps core scopes when master is on" do
      stub_config(enabled: true)
      expect(subject.scope_enabled?(organization, :public)).to be(true)
    end

    it "hides blogs scope when blogs is off" do
      stub_config(enabled: true, blogs_enabled: false)
      expect(subject.scope_enabled?(organization, :blogs)).to be(false)
      expect(subject.scope_enabled?(organization, :public)).to be(true)
    end

    it "keeps surveys scope when forms is on and surveys is off" do
      stub_config(enabled: true, surveys_enabled: false, forms_enabled: true)
      expect(subject.scope_enabled?(organization, :surveys)).to be(true)
    end
  end

  describe ".advertised_scopes filtering" do
    it "filters DoorkeeperConfig.advertised_scopes_for" do
      stub_config(enabled: true, blogs_enabled: false)
      scopes = Decidim::RestFull::Core::DoorkeeperConfig.advertised_scopes_for(organization)
      expect(scopes).not_to include(:blogs)
      expect(scopes).to include(:public)
    end
  end
end
