# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::FireWebhook do
  let(:organization) { create(:organization) }
  let(:url) { "https://example.test/hooks" }

  describe ".resolve_event_name!" do
    it "resolves aliases to catalog events" do
      expect(described_class.resolve_event_name!("step_activated")).to eq(
        "participatory_process.step_activated.succeeded"
      )
      expect(described_class.resolve_event_name!("decidim.step_activated")).to eq(
        "participatory_process.step_activated.succeeded"
      )
    end

    it "accepts exact catalog names" do
      expect(described_class.resolve_event_name!("proposal_creation.succeeded")).to eq(
        "proposal_creation.succeeded"
      )
    end

    it "raises on unknown events" do
      expect { described_class.resolve_event_name!("nope") }.to raise_error(ArgumentError, /Unknown/)
    end
  end

  describe ".call" do
    let!(:participatory_process) { create(:participatory_process, :published, :with_steps, organization:) }

    before do
      stub_request(:post, url).to_return(status: 200, body: "ok")
    end

    it "POSTs a typed envelope with HMAC headers" do
      result = described_class.call(
        url:,
        event: "decidim.step_activated",
        organization:,
        secret: "a" * 64
      )

      expect(result.event_name).to eq("participatory_process.step_activated.succeeded")
      expect(result.status_code).to eq(200)
      expect(result.payload["type"]).to eq("participatory_process.step_activated.succeeded")
      expect(result.payload["data"]).to be_a(Hash)

      expect(WebMock).to(have_requested(:post, url).with do |req|
        expect(req.headers["X-Webhook-Signature"]).to start_with("v1=")
        expect(req.headers["X-Webhook-Timestamp"]).to be_present
        body = JSON.parse(req.body)
        expect(body["type"]).to eq("participatory_process.step_activated.succeeded")
        true
      end)
    end
  end
end
