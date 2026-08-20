# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Api::RestFull::Core::OrganizationWebhookSerializer do
  subject(:serializer) { described_class.new(organization, event_name: "system.organizations.updated", organization:) }

  let(:organization) { create(:organization, available_locales: ["en"]) }

  it "builds an envelope from a real organization" do
    envelope = serializer.envelope

    expect(envelope["type"]).to eq("system.organizations.updated")
    expect(envelope["data"]["type"]).to eq("organization")
    expect(envelope["data"]["id"]).to eq(organization.id.to_s)
    expect(envelope["data"]["attributes"]).to include("host")
  end
end
