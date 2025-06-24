# frozen_string_literal: true

module Decidim
  module RestFull
    describe WebhookJob do
      let(:webhook) { create(:webhook_registration) }
      let(:event) { { "type" => "test.event", "data" => { "data" => { "id" => 1 } } } }
      let(:timestamp) { Time.current.to_i.to_s }

      it "sends a webhook" do
        expect(webhook).to receive(:send_webhook).with(event, timestamp)
        described_class.perform_now(webhook, event, timestamp)
      end

      it "retries the job on WebhookFailedError" do
        allow(webhook).to receive(:send_webhook).and_raise(Decidim::RestFull::WebhookFailedError)

        described_class.perform_now(webhook, event, timestamp)
        expect(described_class).to have_been_enqueued.with(webhook, event, timestamp)
      end

      it "fails the job on StandardError" do
        allow(webhook).to receive(:send_webhook).and_raise(StandardError)
        expect do
          described_class.perform_now(webhook, event, timestamp)
        end.to raise_error(StandardError)
        expect(described_class).not_to have_been_enqueued.with(webhook, event, timestamp)
      end
    end
  end
end
