# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      # CRUD for Decidim::Proposals::ProposalVote (synchronous API).
      class VoteProposalsOperations
        def initialize(execution_context, params)
          @ctx = execution_context
          @params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        end

        def create!
          ProposalVotesOperations.new(@ctx, @params).create!
        end

        def destroy!
          require_user!
          vote = find_vote!
          raise Decidim::RestFull::Core::ApiException::Forbidden, "Cannot remove another user's vote" unless vote.decidim_author_id == current_user.id

          serialized = serialize_vote(vote)
          Decidim::Proposals::UnvoteProposal.call(vote.proposal, current_user) do
            on(:ok) { return serialized }
            on(:invalid) { raise Decidim::RestFull::Core::ApiException::BadRequest, "Vote could not be removed" }
          end
        end

        def index_scope
          scope = Decidim::Proposals::ProposalVote
                  .joins(:proposal)
                  .where(decidim_proposals_proposals: { decidim_component_id: visible_component_ids })
                  .merge(Decidim::Proposals::Proposal.published)
          apply_vote_filters(scope)
        end

        def find_vote!
          scope = Decidim::Proposals::ProposalVote
                  .joins(:proposal)
                  .where(decidim_proposals_proposals: { decidim_component_id: visible_component_ids })
          scope.find(resource_id)
        rescue ActiveRecord::RecordNotFound
          raise Decidim::RestFull::Core::ApiException::NotFound, "Vote not found"
        end

        private

        attr_reader :ctx, :params

        delegate :organization, :current_user, :available_locales, to: :ctx

        def require_user!
          u = current_user
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User required" unless u
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User blocked" if u.blocked_at
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User locked" if u.locked_at
        end

        def resource_id
          (@params[:id] || @params["id"]).to_s
        end

        def participatory_space_visibility
          @participatory_space_visibility ||= Decidim::RestFull::ParticipatorySpaceVisibility.new(
            organization:,
            act_as: current_user
          )
        end

        delegate :in_visible_spaces, :space_class_from_name, to: :participatory_space_visibility

        def visible_component_ids
          components = Decidim::Component.where(manifest_name: "proposals")
          if params.has_key?(:space_manifest)
            components = components.where(participatory_space_type: space_class_from_name(params.require(:space_manifest)))
            components = components.where(participatory_space_id: params.require(:space_id)) if params.has_key?(:space_id)
          end
          in_visible_spaces(components).select(:id)
        end

        def apply_vote_filters(scope)
          filter = params[:filter] || params["filter"]
          return scope unless filter

          filter = filter.to_unsafe_h.stringify_keys if filter.respond_to?(:to_unsafe_h)
          filter = filter.stringify_keys

          if (author_id = filter["creator_id"] || filter["author_id"])
            scope = scope.where(decidim_author_id: author_id)
          end
          scope = scope.where(decidim_proposal_id: filter["proposal_id"]) if filter["proposal_id"]
          if (component_id = filter["component_id"])
            scope = scope.where(decidim_proposals_proposals: { decidim_component_id: component_id })
          end
          if (space_id = filter["participatory_space_id"])
            scope = scope.joins(proposal: :component).where(decidim_components: { participatory_space_id: space_id })
          end
          scope
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
      end
    end
  end
end
