# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Api::RestFull::Proposals::ProposalWebhookSerializer do
  subject(:serializer) { described_class.new(proposal, event_name:, organization:) }

  let(:organization) { create(:organization, available_locales: ["en"]) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:proposal_component, participatory_space: participatory_process) }
  let(:event_name) { "proposal_creation.succeeded" }

  describe "published proposal" do
    let(:proposal) { create(:proposal, :published, component:) }

    it "builds an envelope with type and proposal data" do
      envelope = serializer.envelope

      expect(envelope["type"]).to eq(event_name)
      expect(envelope["data"]["type"]).to eq("proposal")
      expect(envelope["data"]["id"]).to eq(proposal.id.to_s)
      expect(envelope["data"]["attributes"]).to include("title", "body")
    end

    it "exposes event_attributes for WebhookEventForm" do
      attrs = serializer.event_attributes

      expect(attrs[:type]).to eq(event_name)
      expect(attrs[:data]).to have_key(:data)
      expect(attrs[:timestamp]).to be_a(Integer)
    end

    it "uses ProposalSerializer for published proposals" do
      expect(Decidim::Api::RestFull::Proposals::ProposalSerializer).to receive(:new)
        .and_call_original
      serializer.envelope
    end
  end

  describe "draft proposal" do
    let(:proposal) { create(:proposal, component:, published_at: nil) }
    let(:event_name) { "draft_proposal_creation.succeeded" }

    it "uses DraftProposalSerializer for drafts without a separate webhook serializer" do
      expect(Decidim::Api::RestFull::Proposals::DraftProposalSerializer).to receive(:new)
        .and_call_original
      expect(serializer.envelope["data"]["type"]).to eq("draft_proposal")
    end
  end

  describe ".find_example_resource" do
    let!(:published) { create(:proposal, :published, component:) }
    let!(:draft) { create(:proposal, component:, published_at: nil) }

    it "returns a draft for draft_* events" do
      expect(described_class.find_example_resource(organization, event_name: "draft_proposal_creation.succeeded")).to eq(draft)
    end

    it "returns a published proposal for non-draft events" do
      expect(described_class.find_example_resource(organization, event_name: "proposal_creation.succeeded")).to eq(published)
    end
  end
end
