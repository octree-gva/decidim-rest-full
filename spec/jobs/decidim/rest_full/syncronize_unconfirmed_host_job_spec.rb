# frozen_string_literal: true

module Decidim
  module RestFull
    describe SyncronizeUnconfirmedHostJob do
      let(:organization) { create(:organization) }
      let(:organization_id) { organization.id }

      it "syncronizes the unconfirmed host" do
        expect(Decidim::RestFull::SyncronizeUnconfirmedHost).to receive(:call).with(organization)
        described_class.perform_now(organization_id)
      end

      it "retries the job on Decidim::RestFull::ApiException::NotFound" do
        allow(Decidim::RestFull::SyncronizeUnconfirmedHost).to receive(:call).and_raise(Decidim::RestFull::ApiException::NotFound)
        described_class.perform_now(organization_id)

        expect(described_class).to have_been_enqueued.with(organization_id)
      end

      it "discards the job on IPAddr::InvalidAddressError" do
        allow(Decidim::RestFull::SyncronizeUnconfirmedHost).to receive(:call).and_raise(IPAddr::InvalidAddressError)
        described_class.perform_now(organization_id)

        expect(described_class).not_to have_been_enqueued.with(organization_id)
      end

      it "discards the job on Decidim::RestFull::ApiException::BadRequest" do
        allow(Decidim::RestFull::SyncronizeUnconfirmedHost).to receive(:call).and_raise(Decidim::RestFull::ApiException::BadRequest)
        described_class.perform_now(organization_id)

        expect(described_class).not_to have_been_enqueued.with(organization_id)
      end
    end
  end
end
