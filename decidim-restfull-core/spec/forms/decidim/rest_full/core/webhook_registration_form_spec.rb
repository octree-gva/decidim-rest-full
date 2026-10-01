# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::WebhookRegistrationForm do
  let(:organization) { create(:organization) }
  let(:api_client) { create(:api_client, organization:, scopes: ["webhooks"]) }
  let(:event_key) { "proposal_creation.succeeded" }
  let(:subscriptions) { [event_key] }

  before do
    api_client.permissions.create!(permission: event_key, is_event: true)
  end

  def form_with(url:, subscriptions: self.subscriptions)
    described_class
      .from_params(url:, subscriptions:)
      .with_context(api_client:)
  end

  describe "url schema" do
    it "is valid with an https URL" do
      expect(form_with(url: "https://example.org/hooks")).to be_valid
    end

    it "is valid with an http URL" do
      expect(form_with(url: "http://internal.example/hooks")).to be_valid
    end

    it "rejects ftp URLs" do
      form = form_with(url: "ftp://example.org/hooks")
      expect(form).not_to be_valid
      expect(form.errors[:url]).to include("must be a valid HTTP or HTTPS URL")
    end

    it "rejects URLs without a host" do
      form = form_with(url: "http:///hooks")
      expect(form).not_to be_valid
      expect(form.errors[:url]).to include("must be a valid HTTP or HTTPS URL")
    end
  end
end
