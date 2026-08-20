# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Api::RestFull::Meetings::MeetingWebhookSerializer do
  subject(:serializer) { described_class.new(meeting, event_name:, organization:) }

  let(:meeting) { create(:meeting, :published) }
  let(:organization) { meeting.component.organization }
  let(:event_name) { "meetings.upcoming_reminder.succeeded" }

  it "builds an envelope from a real meeting" do
    envelope = serializer.envelope

    expect(envelope["type"]).to eq(event_name)
    expect(envelope["data"]["id"]).to eq(meeting.id.to_s)
  end
end
