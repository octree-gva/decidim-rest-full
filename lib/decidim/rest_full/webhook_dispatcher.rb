# frozen_string_literal: true

module Decidim
  module RestFull
    class WebhookDispatcher
      include Singleton

      def handle_proposals(event_name, data)
        return unless proposal_event?(event_name)

        proposal = data[:resource]
        organization = proposal.organization
        is_draft = proposal.draft?
        published_event_name = if event_name == "decidim.proposals.create_proposal:after" && is_draft
                                 # Created a draft (1st step)
                                 "draft_proposal_creation.succeeded"
                               elsif event_name == "decidim.proposals.update_proposal:after"
                                 # Updated a draft, or updated a published proposal
                                 is_draft ? "draft_proposal_update.succeeded" : "proposal_update.succeeded"
                               elsif event_name == "decidim.events.proposals.proposal_published"
                                 # Published a proposal
                                 "proposal_creation.succeeded"
                               end
        ProposalWebhookJob.perform_later(published_event_name, proposal.id, organization.id)
      end

      private

      def proposal_events
        @proposal_events ||= [
          # Draft created
          "decidim.proposals.create_proposal:after",
          # Published proposal updated
          "decidim.proposals.update_proposal:after",
          # Proposal published
          "decidim.events.proposals.proposal_published"
        ]
      end

      def proposal_event?(event_name)
        proposal_events.include?(event_name)
      end

      def trigger_webhook(event_name, data); end
    end
  end
end
