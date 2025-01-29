# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class ProposalVotesController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :vote, ::Decidim::Proposals::Proposal }
          before_action do
            if (proposal && !component.current_settings.try(:votes_enabled)) || !component.current_settings[:votes_enabled]
              raise Decidim::RestFull::ApiException::BadRequest,
                    "Vote are disabled"
            end
          end
          before_action do
            raise Decidim::RestFull::ApiException::BadRequest, "User required" unless current_user
          end

          def create
            raise Decidim::RestFull::ApiException::BadRequest, "Already voted" if voted?
            raise Decidim::RestFull::ApiException::BadRequest, "Weight: error in the weight field. Negative weight not supported" if weight.negative?
            raise Decidim::RestFull::ApiException::BadRequest, "Weight: error in the weight field. Abstention not supported" if weight.zero? && !support_abstention?
            raise Decidim::RestFull::ApiException::BadRequest, "Weight: error in the weight field. Weight not supported" if !support_weight? && weight > 1

            Decidim::Proposals::VoteProposal.call(proposal, current_user) do
              on(:ok) do |proposal_vote|
                proposal_vote.weight = weight if support_weight?
                proposal.reload
                render json: Decidim::Api::RestFull::ProposalSerializer.new(
                  proposal,
                  params: {
                    only: [],
                    locales: available_locales,
                    host: current_organization.host,
                    act_as: act_as
                  }
                ).serializable_hash
              end

              on(:invalid) do
                raise Decidim::RestFull::ApiException::BadRequest
              end
            end
          end

          protected

          def support_weight?
            awesome? && voting_manifest
          end

          def support_abstention?
            awesome? && component.settings[:voting_cards_show_abstain]
          end

          def voting_manifest
            @voting_manifest ||= component.settings[:awesome_voting_manifest]
          end

          def weight
            @weight ||= params.require(:data).require(:weight).to_i
          end

          def awesome?
            Object.const_defined?("Decidim::DecidimAwesome") && Decidim::DecidimAwesome.enabled?(:weighted_proposal_voting)
          end

          def voted?
            proposal_votes.exists?
          end

          def last_vote
            proposal_votes.last
          end

          def proposal_votes
            proposal.votes.where(decidim_author_id: current_user.id)
          end

          def proposal
            @proposal ||= collection.find(params.require(:resource_id))
          end

          def proposal_component
            @proposal_component ||= proposal.component
          end

          def order_columns
            %w(rand published_at)
          end

          def default_order_column
            "published_at"
          end

          def component_manifest
            "proposals"
          end

          def model_class
            Decidim::Proposals::Proposal.published
          end

          def collection
            model_class.where(component: component)
          end
        end
      end
    end
  end
end
