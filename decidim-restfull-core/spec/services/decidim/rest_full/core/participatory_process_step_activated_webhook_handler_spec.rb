# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::ParticipatoryProcessStepActivatedWebhookHandler do
  include ActiveJob::TestHelper

  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:step) { participatory_process.steps.first }

  it "enqueues SpaceWebhookJob for step_activated" do
    expect do
      described_class.call(
        described_class::HANDLED_EVENT,
        { resource: step }
      )
    end.to have_enqueued_job(Decidim::RestFull::Core::SpaceWebhookJob).with(
      described_class::WEBHOOK_EVENT,
      participatory_process.id,
      organization.id,
      step.id
    )
  end

  it "accepts ActiveSupport::Notifications::Event payloads" do
    event = ActiveSupport::Notifications::Event.new(
      described_class::HANDLED_EVENT,
      Time.current,
      Time.current,
      "txn",
      { resource: step }
    )

    expect do
      described_class.call(described_class::HANDLED_EVENT, event)
    end.to have_enqueued_job(Decidim::RestFull::Core::SpaceWebhookJob)
  end

  it "ignores other events" do
    expect do
      described_class.call("decidim.events.other", { resource: step })
    end.not_to have_enqueued_job(Decidim::RestFull::Core::SpaceWebhookJob)
  end

  it "ignores non-step resources" do
    expect do
      described_class.call(described_class::HANDLED_EVENT, { resource: participatory_process })
    end.not_to have_enqueued_job(Decidim::RestFull::Core::SpaceWebhookJob)
  end

  it "ignores unknown payload shapes" do
    expect do
      described_class.call(described_class::HANDLED_EVENT, :not_a_hash)
    end.not_to have_enqueued_job(Decidim::RestFull::Core::SpaceWebhookJob)
  end
end
