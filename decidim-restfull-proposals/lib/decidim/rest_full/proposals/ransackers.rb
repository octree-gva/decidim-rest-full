# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      # Proposal-specific Ransackers (only loaded with decidim-restfull-proposals).
      module Ransackers
        module_function

        def register!
          return unless defined?(Decidim::Proposals::Proposal)

          register_state_ransacker!
          register_weight_proposal_ransacker!
        end

        def register_state_ransacker!
          Decidim::Proposals::Proposal.ransacker :state do |_r|
            Arel.sql(<<~SQL.squish
              COALESCE(
                (SELECT
                  tstate.token
                FROM #{Decidim::Proposals::ProposalState.table_name} AS tstate
                WHERE
                  decidim_proposals_proposals.decidim_proposals_proposal_state_id = tstate.id
                LIMIT 1), ''
              )
            SQL
                    )
          end
        end

        def register_weight_proposal_ransacker!
          Decidim::Proposals::Proposal.ransacker :voted_weight, args: [:parent, :ransacker_args] do |_parent, _ransacker_args|
            current_user = ::Decidim::Api::RestFull::Proposals::ProposalsController::CurrentUser.user
            raise "current_user is nil" if current_user.nil?

            awesome_support = Object.const_defined?("Decidim::DecidimAwesome") && Decidim::DecidimAwesome.enabled?(:weighted_proposal_voting)
            unless awesome_support
              return Arel.sql(<<~SQL.squish
                (
                  SELECT
                    '1' AS weight
                  FROM #{Decidim::Proposals::ProposalVote.table_name} AS tvote
                  WHERE
                    tvote.decidim_proposal_id = #{Decidim::Proposals::Proposal.table_name}.id
                    AND tvote.decidim_author_id = #{current_user.id.to_i}
                  LIMIT 1
                )
              SQL
                             )
            end

            Arel.sql(<<~SQL.squish
              (
                SELECT
                  CASE
                    WHEN tweight.id IS NULL THEN '1'
                    ELSE CAST(tweight.weight AS VARCHAR)
                  END AS weight
                FROM #{Decidim::Proposals::ProposalVote.table_name} AS tvote
                LEFT JOIN #{Decidim::DecidimAwesome::VoteWeight.table_name} AS tweight
                  ON tvote.id = tweight.proposal_vote_id
                WHERE
                  tvote.decidim_proposal_id = #{Decidim::Proposals::Proposal.table_name}.id
                  AND tvote.decidim_author_id = #{current_user.id.to_i}
                LIMIT 1
              )
            SQL
                    )
          end
        end
      end
    end
  end
end
