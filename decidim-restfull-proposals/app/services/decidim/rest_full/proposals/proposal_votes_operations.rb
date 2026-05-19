# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      # Shared logic for casting a proposal vote (sync + async).
      class ProposalVotesOperations
        def initialize(execution_context, params)
          @ctx = execution_context
          @params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        end

        def create!
          require_user!
          validate_component_votes!
          validate_vote_preconditions!
          serialized = cast_vote!
          return serialize_proposal_with_vote(serialized) if include_full_proposal?

          serialized
        end

        private

        attr_reader :ctx

        delegate :organization, :current_user, :available_locales, to: :ctx

        def act_as
          current_user
        end

        def participatory_space_visibility
          @participatory_space_visibility ||= Decidim::RestFull::ParticipatorySpaceVisibility.new(organization:, act_as:)
        end

        delegate :in_visible_spaces, :visible_spaces, :visible_scope_for, :space_class_from_name, to: :participatory_space_visibility

        def require_user!
          u = current_user
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User required" unless u
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User blocked" if u.blocked_at
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User locked" if u.locked_at
        end

        def validate_component_votes!
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Vote are disabled" unless proposal_component.current_settings[:votes_enabled]
        end

        def validate_vote_preconditions!
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Already voted" if voted?

          validate_weight!
        end

        def validate_weight!
          if weight.negative?
            raise Decidim::RestFull::Core::ApiException::BadRequest,
                  "Weight: error in the weight field. Negative weight not supported"
          end
          if weight.zero? && !support_abstention?
            raise Decidim::RestFull::Core::ApiException::BadRequest,
                  "Weight: error in the weight field. Abstention not supported"
          end
          return unless !support_weight? && weight > 1

          raise Decidim::RestFull::Core::ApiException::BadRequest,
                "Weight: error in the weight field. Weight not supported"
        end

        def cast_vote!
          serialized = nil
          Decidim::Proposals::VoteProposal.call(proposal, current_user) do
            on(:ok) do |proposal_vote|
              proposal_vote.weight = weight if support_weight?
              proposal_vote.save! if proposal_vote.changed?
              serialized = serialize_vote(proposal_vote)
            end
            on(:invalid) do
              raise Decidim::RestFull::Core::ApiException::BadRequest, "Vote is invalid"
            end
          end
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Vote is invalid" if serialized.nil?

          serialized
        end

        def support_weight?
          awesome? && voting_manifest
        end

        def support_abstention?
          awesome? && proposal_component.settings[:voting_cards_show_abstain]
        end

        def voting_manifest
          @voting_manifest ||= proposal_component.settings[:awesome_voting_manifest]
        end

        def weight
          @weight ||= @params.require(:data).require(:weight).to_i
        end

        def awesome?
          Object.const_defined?("Decidim::DecidimAwesome") && Decidim::DecidimAwesome.enabled?(:weighted_proposal_voting)
        end

        def voted?
          proposal_votes.exists?
        end

        def proposal_votes
          proposal.votes.where(decidim_author_id: current_user.id)
        end

        def proposal
          @proposal ||= collection.find(@params.require(:proposal_id))
        end

        def proposal_component
          @proposal_component ||= proposal.component
        end

        def model_class
          Decidim::Proposals::Proposal.published
        end

        def collection
          filter_for_context(model_class)
        end

        def filter_for_context(query)
          components_filters = Decidim::Component.all
          if @params.has_key?(:space_manifest)
            components_filters = components_filters.where(participatory_space_type: space_class_from_name(@params.require(:space_manifest)))
            components_filters = components_filters.where(participatory_space_id: @params.require(:space_id)) if @params.has_key?(:space_id)
          end
          visible_ids = in_visible_spaces(components_filters).select(:id)
          query.where(decidim_component_id: visible_ids)
        end

        def include_full_proposal?
          ActiveModel::Type::Boolean.new.cast(@params[:include_proposal])
        end

        def serialize_vote(vote)
          Decidim::Api::RestFull::Proposals::VoteProposalSerializer.new(
            vote,
            params: {
              locales: available_locales,
              host: organization.host,
              act_as: current_user
            }
          ).serializable_hash
        end

        def serialize_proposal_with_vote(_vote_payload)
          proposal.reload
          Decidim::Api::RestFull::Proposals::ProposalSerializer.new(
            proposal,
            params: {
              only: [],
              locales: available_locales,
              host: organization.host,
              act_as: current_user,
              client_id: @ctx.client_id
            }
          ).serializable_hash
        end
      end
    end
  end
end
