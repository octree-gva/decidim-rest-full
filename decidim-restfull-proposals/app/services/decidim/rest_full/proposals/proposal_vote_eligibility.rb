# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      # Shared vote eligibility for proposal / proposal-component REST meta.
      # Reuses Decidim Awesome VotesByProposalStatus when that feature is available.
      class ProposalVoteEligibility
        class << self
          def voting_enabled?(component)
            settings = component.current_settings.to_h
            settings[:votes_enabled] && !settings[:votes_blocked]
          end

          def awesome_votes_enabled_by_status(component)
            return false unless awesome_status_feature?

            ActiveModel::Type::Boolean.new.cast(
              component.current_settings.try(:awesome_votes_enabled_by_status)
            ) || false
          end

          def awesome_votes_enabled_states(component)
            return [] unless awesome_status_feature?

            Array(component.current_settings.try(:awesome_votes_enabled_states)).compact_blank.map(&:to_s)
          end

          def status_filter(component)
            return NullStatusFilter.new unless awesome_status_feature?

            Decidim::DecidimAwesome::Proposals::VotesByProposalStatus.new(component.current_settings)
          end

          def proposal_can_vote?(proposal)
            return false unless proposal.published?
            return false if proposal.withdrawn?
            return false unless voting_enabled?(proposal.component)

            filter = status_filter(proposal.component)
            if filter.active?
              filter.allowed?(proposal)
            else
              !proposal.rejected?
            end
          end

          def votable_scope(component)
            base = ::Decidim::Proposals::Proposal
                   .where(decidim_component_id: component.id)
                   .published
                   .not_withdrawn

            filter = status_filter(component)
            return base.except_rejected unless filter.active?

            tokens = filter.allowed_tokens
            return base.none if tokens.blank?

            state_table = ::Decidim::Proposals::ProposalState.table_name
            base.left_joins(:proposal_state).where(
              "#{state_table}.token IN (:tokens) OR (#{state_table}.id IS NULL AND :includes_not_answered)",
              tokens:,
              includes_not_answered: tokens.include?("not_answered")
            )
          end

          def unvoted_voteable_proposals_exist?(component, user)
            base = votable_scope(component)
            return false unless base.exists?

            voted_ids = ::Decidim::Proposals::ProposalVote
                        .where(decidim_author_id: user.id)
                        .distinct
                        .pluck(:decidim_proposal_id)

            return true if voted_ids.blank?

            base.where.not(id: voted_ids).exists?
          end

          def awesome_status_feature?
            Decidim::Toggle.gem_present?("decidim-decidim_awesome") &&
              defined?(::Decidim::DecidimAwesome) &&
              ::Decidim::DecidimAwesome.enabled?(:votes_by_proposal_status)
          end
        end

        # Inactive stand-in when Awesome / votes_by_proposal_status is unavailable.
        class NullStatusFilter
          def active?
            false
          end

          def allowed?(_proposal)
            true
          end

          def allowed_tokens
            []
          end
        end
      end
    end
  end
end
