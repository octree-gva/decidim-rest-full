# frozen_string_literal: true

module Decidim
  module RestFull
    describe ProposalWebhookJob do
      let(:proposal) { create(:proposal) }
      let(:organization) { proposal.organization }
      let(:proposal_id) { proposal.id }
      let(:organization_id) { organization.id }
      let(:api_client) { create(:api_client, organization: organization, scopes: ["proposals"]) }

      before do
        allow(Decidim::RestFull::WebhookJob).to receive(:perform_later).and_return(true)
      end

      context "when sending a proposal_creation.succeeded event" do
        let(:event_name) { "proposal_creation.succeeded" }
        let!(:webhooks) { create_list(:webhook_registration, 3, api_client: api_client, subscriptions: [event_name]) }
        let!(:webhook_other) { create(:webhook_registration, api_client: api_client, subscriptions: ["whatever"]) }

        before do
          # Define permissions for the webohook api_client
          api_client.permissions.create(permission: event_name)
          api_client.save!
          api_client.reload
        end

        it "call subscribed webhooks" do
          expect(Decidim::RestFull::WebhookJob).to receive(:perform_later) do |webhook_registration, _payload, _timestamp|
            expect(webhook_registration).to be_in(webhooks)
          end
          described_class.perform_now(event_name, proposal_id, organization_id)
        end

        it "does not call other webhooks" do
          expect(Decidim::RestFull::WebhookJob).not_to receive(:perform_later).with(webhook_other)
          described_class.perform_now(event_name, proposal_id, organization_id)
        end

        it "serialize proposal with DraftProposalSerializer if it is a draft" do
          proposal.update(published_at: nil)

          expect(Decidim::Api::RestFull::DraftProposalSerializer).to receive(:new).with(proposal, kind_of(Hash)).and_call_original
          described_class.perform_now(event_name, proposal_id, organization_id)
        end

        it "serialize proposal with ProposalSerializer if it is a draft" do
          proposal.update(published_at: nil)

          expect(Decidim::Api::RestFull::ProposalSerializer).to receive(:new).with(proposal, kind_of(Hash)).and_call_original
          described_class.perform_now(event_name, proposal_id, organization_id)
        end
      end
    end
  end
end
