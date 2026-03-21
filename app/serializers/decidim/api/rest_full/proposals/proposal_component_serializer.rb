# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposals
        class ProposalComponentSerializer < ::Decidim::Api::RestFull::Core::ComponentSerializer
          extend ::Decidim::Api::RestFull::Core::Helpers::ResourceLinksHelper

          def self.resources_for(component, act_as)
            resources = ::Decidim::Proposals::Proposal.where(component:)
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

          def self.draft_for(component_id, user_id, client_id)
            Decidim::Proposals::Proposal.joins(
              :rest_full_application,
              :coauthorships
            ).where(
              rest_full_application: { api_client_id: client_id },
              decidim_component_id: component_id,
              published_at: nil,
              decidim_coauthorships: { decidim_author_id: user_id }
            ).limit(1)
          end

          def self.vote_weights_from_i18n(i18n_values, vote_manifest, available_locales, has_abstain)
            options = i18n_values.reject { |k| k.end_with? "short" }
            options = options.map do |k, _v|
              {
                weight: k.to_s.split("_").last.to_i,
                label: available_locales.index_with do |locale|
                  I18n.t("decidim.decidim_awesome.voting.#{vote_manifest}.weights.#{k}", locale:)
                end
              }
            end
            return options if has_abstain

            options.select { |value| (value[:weight]).positive? }
          end

          meta do |component, params|
            metas = ::Decidim::Api::RestFull::Core::ComponentSerializer.default_meta(component)
            component = Decidim::Component.find(component.id) unless component.is_a?(Decidim::Component)
            available_locales = params[:locales]

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
            settings_keys = %w(
              endorsements_enabled
              votes_enabled
              creation_enabled
              proposal_answering_enabled
              amendment_creation_enabled
              amendment_reaction_enabled
              amendment_promotion_enabled
            )
            settings_keys.each do |key|
              metas[key.to_sym] = current_settings_h[key.to_sym]
            end

            resources = ::Decidim::Proposals::Proposal.where(component:)
            act_as = params[:act_as]
            proposal_limit = metas[:proposal_limit]
            metas[:can_create_proposals] = false
            if metas[:creation_enabled] && act_as.present?
              metas[:can_create_proposals] = proposal_limit.zero? ||
                                             resources.joins(:coauthorships).published.where(
                                               coauthorships: { decidim_author_id: act_as.id }
                                             ).count < proposal_limit
            end
            metas[:can_vote] = metas[:votes_enabled]
            metas[:can_endorse] = metas[:endorsements_enabled]
            metas[:can_comment] = metas[:comments_enabled]

            has_abstain = settings_h[:voting_cards_show_abstain]
            if metas[:can_vote]
              metas[:votes] = begin
                vote_manifest = settings_h[:awesome_voting_manifest]
                i18n_key = "decidim.decidim_awesome.voting.#{vote_manifest}.weights"
                default_votes = [
                  {
                    label: available_locales.index_with { |locale| I18n.t("decidim.components.proposals.actions.vote", locale:) },
                    weight: 1
                  }
                ]

                if has_abstain
                  default_votes << {
                    label: available_locales.index_with { |locale| I18n.t("decidim.decidim_awesome.voting.voting_cards.weights.weight_0", locale:) },
                    weight: 0
                  }
                end

                if settings_h.include?(:awesome_voting_manifest) && I18n.exists?(i18n_key)
                  i18n_values = I18n.t("decidim.decidim_awesome.voting.#{vote_manifest}.weights", object: true)
                  i18n_values.empty? ? default_votes : vote_weights_from_i18n(i18n_values, vote_manifest, available_locales, has_abstain)
                else
                  default_votes
                end
              end
            end

            metas
          end

          link :draft, if: (proc do |component, params|
            next false unless params[:act_as]

            draft_for(component.id, params[:act_as].id, params[:client_id]).exists?
          end) do |component, params|
            draft = draft_for(component.id, params[:act_as].id, params[:client_id]).first
            infos = link_infos_from_resource(draft)
            {
              href: link_join(params[:host], "draft_proposals", draft.id),
              title: "Draft Details",
              rel: "resource",
              meta: {
                **infos,
                action_method: "GET"
              }
            }
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
end
