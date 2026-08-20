# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Api::RestFull::Core::UserWebhookSerializer do
  subject(:serializer) { described_class.new(user, event_name: "user.created", organization:) }

  let(:organization) { create(:organization, available_locales: ["en"]) }
  let(:user) { create(:user, organization:) }

  it "builds an envelope from a real user" do
    envelope = serializer.envelope

    expect(envelope["type"]).to eq("user.created")
    expect(envelope["data"]["type"]).to eq("user")
    expect(envelope["data"]["id"]).to eq(user.id.to_s)
    expect(envelope["data"]["attributes"]["nickname"]).to eq(user.nickname)
  end
end
