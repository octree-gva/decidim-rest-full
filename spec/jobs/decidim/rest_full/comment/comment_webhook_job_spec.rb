# frozen_string_literal: true

require "spec_helper"
require "decidim/proposals/test/factories"
require "decidim/comments/test/factories"

RSpec.describe Decidim::RestFull::Comment::CommentWebhookJob do
  let(:proposal) { create(:proposal) }
  let!(:comment) do
    create(
      :comment,
      commentable: proposal,
      root_commentable: proposal,
      participatory_space: proposal.participatory_space
    )
  end
  let(:organization) { proposal.organization }
  let(:comment_id) { comment.id }
  let(:organization_id) { organization.id }
  let(:api_client) { create(:api_client, organization:, scopes: ["comments"]) }

  before do
    allow(Decidim::RestFull::WebhookJob).to receive(:perform_later).and_return(true)
  end

  context "when sending a comment_creation.succeeded event" do
    let(:event_name) { "comment_creation.succeeded" }
    let!(:webhooks) { create_list(:webhook_registration, 2, api_client:, subscriptions: [event_name]) }
    let!(:webhook_other) { create(:webhook_registration, api_client:, subscriptions: ["other.event"]) }

    before do
      api_client.permissions.create!(permission: event_name)
      api_client.save!
      api_client.reload
    end

    it "calls subscribed webhooks" do
      expect(Decidim::RestFull::WebhookJob).to receive(:perform_later) do |webhook_registration, _payload, _timestamp|
        expect(webhook_registration).to be_in(webhooks)
      end
      described_class.perform_now(event_name, comment_id, organization_id)
    end

    it "does not call unsubscribed webhooks" do
      expect(Decidim::RestFull::WebhookJob).not_to receive(:perform_later).with(webhook_other)
      described_class.perform_now(event_name, comment_id, organization_id)
    end
  end
end
