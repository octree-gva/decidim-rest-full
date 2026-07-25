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
