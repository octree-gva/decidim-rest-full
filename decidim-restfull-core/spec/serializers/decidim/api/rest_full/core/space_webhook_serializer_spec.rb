# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Api::RestFull::Core::SpaceWebhookSerializer do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, :published, :with_steps, organization:) }
  let(:step) { participatory_process.steps.first }
  let(:event_name) { "participatory_process.step_activated.succeeded" }

  describe "#envelope" do
    it "uses the event name as type and space JSON:API data with step meta" do
      envelope = described_class.new(participatory_process, event_name:, organization:, step:).envelope

      expect(envelope["type"]).to eq(event_name)
      expect(envelope["data"]["id"]).to eq(participatory_process.id.to_s)
      expect(envelope["data"]["meta"]["active_step_id"]).to eq(step.id.to_s)
      expect(envelope["data"]["meta"]["active_step_position"]).to eq(step.position)
      expect(envelope["data"]["meta"]["active_step_title"]).to be_present
    end

    it "omits step meta when step is nil" do
      allow(participatory_process).to receive(:active_step).and_return(nil)
      envelope = described_class.new(participatory_process, event_name:, organization:, step: nil).envelope
      meta = envelope.dig("data", "meta") || {}

      expect(meta).not_to have_key("active_step_id")
    end

    it "uses a string step title when title is not a hash" do
      allow(step).to receive(:title).and_return("Kickoff")
      envelope = described_class.new(participatory_process, event_name:, organization:, step:).envelope

      expect(envelope["data"]["meta"]["active_step_title"]).to eq("Kickoff")
    end
  end

  describe ".find_example_resource" do
    it "returns a process for the organization" do
      process = participatory_process
      expect(described_class.find_example_resource(organization, event_name:)).to eq(process)
    end
  end
end
