# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::SyncronizeUnconfirmedHostJob do
  let(:organization) { create(:organization, available_locales: ["en"]) }
  let(:organization_id) { organization.id }

  it "syncronizes the unconfirmed host" do
    expect(Decidim::RestFull::Core::SyncronizeUnconfirmedHost).to receive(:call).with(organization)
    described_class.perform_now(organization_id)
  end

  it "retries the job on Decidim::RestFull::Core::ApiException::NotFound" do
    allow(Decidim::RestFull::Core::SyncronizeUnconfirmedHost).to receive(:call).and_raise(Decidim::RestFull::Core::ApiException::NotFound)
    described_class.perform_now(organization_id)

    expect(described_class).to have_been_enqueued.with(organization_id)
  end

  it "discards the job on IPAddr::InvalidAddressError" do
    allow(Decidim::RestFull::Core::SyncronizeUnconfirmedHost).to receive(:call).and_raise(IPAddr::InvalidAddressError)
    described_class.perform_now(organization_id)

    expect(described_class).not_to have_been_enqueued.with(organization_id)
  end

  it "discards the job on Decidim::RestFull::Core::ApiException::BadRequest" do
    allow(Decidim::RestFull::Core::SyncronizeUnconfirmedHost).to receive(:call).and_raise(Decidim::RestFull::Core::ApiException::BadRequest)
    described_class.perform_now(organization_id)

    expect(described_class).not_to have_been_enqueued.with(organization_id)
  end
end
