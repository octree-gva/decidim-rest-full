# frozen_string_literal: true

module Decidim
  module RestFull
    module ProposalsControllerOverride
      extend ActiveSupport::Concern

      included do
        # Alias the original proposal_draft method
        alias_method :original_proposal_draft, :proposal_draft

        def proposal_draft_without_external_client_ids
          Decidim::Proposals::Proposal
            .from_all_author_identities(current_user)
            .not_hidden
            .only_amendables
            .joins("LEFT OUTER JOIN proposal_application_ids ON proposal_application_ids.proposal_id = decidim_proposals_proposals.id")
            .where(component: current_component, proposal_application_ids: { id: nil })
            .find_by(published_at: nil)
        end

        alias_method :proposal_draft, :proposal_draft_without_external_client_ids
      end
    end
  end
end
