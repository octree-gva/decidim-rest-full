# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Meetings::MeetingWebhookJob do
  let(:meeting) { create(:meeting, :published) }
  let(:organization) { meeting.component.organization }
  let!(:api_client) { create(:api_client, organization:, scopes: ["meetings"]) }
  let(:event_name) { "meetings.upcoming_reminder.succeeded" }

  before do
    allow(Decidim::RestFull::Core::WebhookJob).to receive(:perform_later).and_return(true)
    api_client.permissions.create!(permission: event_name)
  end

  it "calls WebhookJob for webhook registrations subscribed to this event" do
    webhook = create(:webhook_registration, api_client:, subscriptions: [event_name])

    expect(Decidim::RestFull::Core::WebhookJob).to receive(:perform_later) do |registration, *_args|
      expect(registration).to eq(webhook)
    end

    described_class.perform_now(event_name, meeting.id, organization.id)
  end

  it "serializes the meeting with Meetings::MeetingSerializer" do
    create(:webhook_registration, api_client:, subscriptions: [event_name])

    expect(Decidim::Api::RestFull::Meetings::MeetingSerializer).to receive(:new).with(meeting, kind_of(Hash)).and_call_original

    described_class.perform_now(event_name, meeting.id, organization.id)
  end
end
