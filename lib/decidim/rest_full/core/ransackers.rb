# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      module Ransackers
        def self.register_ransackers!
          register_weight_proposal_ransacker!
          register_state_ransacker!
          register_component_id_ransacker!
          register_participatory_space_ransacker!
          register_user_id_ransacker!
        end

        def self.register_user_id_ransacker!
          Decidim::User.ransacker :id do |_r|
            Arel.sql('CAST("decidim_users"."id" AS VARCHAR)')
          end
        end

        def self.register_participatory_space_ransacker!
          existing_manifests = Decidim.participatory_space_registry.manifests.select do |manifest|
            manifest.model_class_name.constantize.table_exists?
          end
          existing_manifests.each do |manifest|
            model = manifest.model_class_name.constantize
            model.ransacker :manifest_name do |_r|
              Arel.sql("'#{manifest.name}'")
            end
            model.ransacker :id do |_r|
              Arel.sql("CAST(\"#{model.table_name}\".\"id\" AS VARCHAR)")
            end
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
          # Skip when DB is not available (e.g. OpenAPI doc generation, CI without DB).
        end

        def self.register_component_id_ransacker!
          Decidim::Component.ransacker :id do |_r|
            Arel.sql('CAST("decidim_components"."id" AS VARCHAR)')
          end
        end

        def self.register_state_ransacker!
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

        def self.register_weight_proposal_ransacker!
          Decidim::Proposals::Proposal.ransacker :voted_weight, args: [:parent, :ransacker_args] do |_parent, _ransacker_args|
            current_user = ::Decidim::Api::RestFull::Proposals::ProposalsController::CurrentUser.user
            # Access current_user from the ransacker_args context
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
