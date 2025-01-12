# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ProposalComponentSerializer < ComponentSerializer
        def self.resources_for(component, act_as)
          resources = ::Decidim::Proposals::Proposal.where(component: component)
          if act_as.nil?
            resources.published
          else
            resources.joins(:coauthorships).published.or(
              resources.joins(:coauthorships).where(
                published_at: nil,
                coauthorships: { decidim_author_id: act_as.id }
              )
            )
          end
        end
        meta do |component, params|
          metas = ComponentSerializer.default_meta(component)
          proposal_limit = component.settings.proposal_limit
          settings_h = component.settings.to_h
          current_settings_h = component.current_settings.to_h
          settings_keys = %w(
            amendments_enabled
            attachments_allowed
            collaborative_drafts_enabled
            comments_enabled
            comments_max_length
            default_sort_order
            geocoding_enabled
            minimum_votes_per_user
            official_proposals_enabled
            participatory_texts_enabled
            proposal_edit_before_minutes
            proposal_edit_time
            proposal_limit
            resources_permissions_enabled
            scopes_enabled
            threshold_per_proposal
            vote_limit
          )
          settings_keys.each do |key|
            metas[key.to_sym] = settings_h[key.to_sym]
          end
          settings_keys = %w(endorsements_enabled votes_enabled creation_enabled proposal_answering_enabled amendment_creation_enabled amendment_reaction_enabled
                             amendment_promotion_enabled)
          settings_keys.each do |key|
            metas[key.to_sym] = current_settings_h[key.to_sym]
          end

          resources = ::Decidim::Proposals::Proposal.where(component: component)
          act_as = params[:act_as]
          metas[:can_create_proposals] = false
          if metas[:creation_enabled] && act_as.present?
            metas[:can_create_proposals] = proposal_limit.zero? ||
                                           resources.joins(:coauthorships).published.where(
                                             coauthorships: { decidim_author_id: act_as.id }
                                           ).count < proposal_limit
          end
          metas[:can_vote] = metas[:votes_enabled]
          metas[:can_comment] = metas[:comments_enabled]
          metas
        end

        has_many :resources, meta: (proc do |component, params|
          { count: resources_for(component, params[:act_as]).count }
        end) do |component, params|
          resources_for(component, params[:act_as]).limit(50)
        end
      end
    end
  end
end
