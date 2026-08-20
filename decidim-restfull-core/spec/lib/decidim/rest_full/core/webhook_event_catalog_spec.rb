# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::WebhookEventCatalog do
  describe ".example_payload_for" do
    let(:organization) { create(:organization, available_locales: ["en"]) }
    let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
    let(:component) { create(:proposal_component, participatory_space: participatory_process) }
    let!(:proposal) { create(:proposal, :published, component:) }

    it "serializes a real proposal via ProposalWebhookSerializer" do
      payload = described_class.example_payload_for("proposal_creation.succeeded", organization:)

      expect(payload["type"]).to eq("proposal_creation.succeeded")
      expect(payload["data"]["type"]).to eq("proposal")
      expect(payload["data"]["id"]).to eq(proposal.id.to_s)
    end

    it "raises for unknown events" do
      expect do
        described_class.example_payload_for("does.not.exist", organization:)
      end.to raise_error(KeyError)
    end

    it "raises when no sample resource exists" do
      empty_org = create(:organization, available_locales: ["en"])

      expect do
        described_class.example_payload_for("proposal_creation.succeeded", organization: empty_org)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
