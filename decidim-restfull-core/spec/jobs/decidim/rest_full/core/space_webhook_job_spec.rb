# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::SpaceWebhookJob do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:step) { participatory_process.steps.first }
  let(:event_name) { "participatory_process.step_activated.succeeded" }
  let(:api_client) { create(:api_client, organization:, scopes: ["public"]) }

  before do
    allow(Decidim::RestFull::Core::WebhookJob).to receive(:perform_later).and_return(true)
  end

  it "dispatches subscribed webhooks" do
    api_client.permissions.create!(permission: event_name, is_event: true)
    webhooks = create_list(:webhook_registration, 2, api_client:, subscriptions: [event_name])
    create(:webhook_registration, api_client:, subscriptions: ["other.event"])

    expect(Decidim::RestFull::Core::WebhookJob).to receive(:perform_later) do |registration, _payload, _timestamp|
      expect(webhooks).to include(registration)
    end.at_least(:once)

    described_class.perform_now(event_name, participatory_process.id, organization.id, step.id)
  end

  it "uses active_step when step_id is omitted" do
    api_client.permissions.create!(permission: event_name, is_event: true)
    create(:webhook_registration, api_client:, subscriptions: [event_name])

    expect(Decidim::RestFull::Core::WebhookJob).to receive(:perform_later).at_least(:once)
    described_class.perform_now(event_name, participatory_process.id, organization.id)
  end

  it "skips when the event form is invalid" do
    api_client.permissions.create!(permission: event_name, is_event: true)
    create(:webhook_registration, api_client:, subscriptions: [event_name])

    allow_any_instance_of(Decidim::Api::RestFull::Core::SpaceWebhookSerializer).to receive(:event_attributes).and_return( # rubocop:disable RSpec/AnyInstance
      type: event_name,
      data: { "data" => { "id" => "1" } },
      timestamp: Time.current.to_i
    )
    form = instance_double(
      Decidim::RestFull::Core::WebhookEventForm,
      valid?: false,
      errors: instance_double(ActiveModel::Errors, full_messages: ["bad"])
    )
    allow(Decidim::RestFull::Core::WebhookEventForm).to receive(:new).and_return(form)
    allow(form).to receive(:with_context).and_return(form)

    expect(Decidim::RestFull::Core::WebhookJob).not_to receive(:perform_later)
    expect(Rails.logger).to receive(:warn).with(/Invalid space webhook event/)
    described_class.perform_now(event_name, participatory_process.id, organization.id, step.id)
  end

  it "no-ops when no api client has the event permission" do
    expect(Decidim::RestFull::Core::WebhookJob).not_to receive(:perform_later)
    described_class.perform_now(event_name, participatory_process.id, organization.id, step.id)
  end
end
