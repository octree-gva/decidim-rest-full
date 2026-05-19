# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module VoteProposals
        class VoteProposalsController < Decidim::Api::RestFull::ApplicationController
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :proposals }
          before_action :authorize_vote!, only: [:create, :create_sync]
          before_action :authorize_unvote!, only: [:destroy]
          before_action :authorize_read!, only: [:index, :show]
          before_action :require_user!, only: [:create, :create_sync, :destroy]
          before_action :validate_votes_enabled!, only: [:create, :create_sync]

          def index
            page = paginate(operations.index_scope)
            payload = Decidim::Api::RestFull::Proposals::VoteProposalSerializer.new(
              page,
              params: serializer_params
            ).serializable_hash
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(page))
          end

          def show
            vote = operations.find_vote!
            payload = Decidim::Api::RestFull::Proposals::VoteProposalSerializer.new(
              vote,
              params: serializer_params
            ).serializable_hash
            render_json_with_conditional_get(payload, fingerprint: resource_fingerprint_for(vote))
          end

          def create
            enqueue_rest_full_api_job!("vote_proposals#create")
          end

          def create_sync
            render json: Decidim::RestFull::SyncRunner.call { operations.create! }
          end

          def destroy
            render json: Decidim::RestFull::SyncRunner.call { operations.destroy! }
          end

          private

          def operations
            Decidim::RestFull::Proposals::VoteProposalsOperations.new(api_execution_context, params)
          end

          def require_user!
            raise Decidim::RestFull::Core::ApiException::BadRequest, "User required" unless current_user
          end

          def validate_votes_enabled!
            proposal_id = params[:proposal_id] || params.dig(:data, :proposal_id)
            proposal = Decidim::Proposals::Proposal.published.find_by(id: proposal_id)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Proposal not found" unless proposal

            raise Decidim::RestFull::Core::ApiException::BadRequest, "Vote are disabled" unless proposal.component.current_settings[:votes_enabled]
          end

          def authorize_read!
            ability.authorize! :read, ::Decidim::Proposals::Proposal
          end

          def authorize_vote!
            ability.authorize! :vote, ::Decidim::Proposals::Proposal
          end

          def authorize_unvote!
            ability.authorize! :unvote, ::Decidim::Proposals::Proposal
          end

          def serializer_params
            {
              locales: available_locales,
              host: current_organization.host,
              act_as: current_user
            }
          end
        end
      end
    end
  end
end
