# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposals
        class ProposalsController < Decidim::Api::RestFull::Core::ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :read, ::Decidim::Proposals::Proposal }
          class CurrentUser < ActiveSupport::CurrentAttributes
            attribute :user
          end
          before_action { CurrentUser.user = current_user }
          def index
            query = collection.ransack(params[:filter])

            results = query.result
            render json: Decidim::Api::RestFull::Proposals::ProposalSerializer.new(
              paginate(ordered(results)),
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                client_id:,
                act_as:
              }
            ).serializable_hash
          end

          def show
            render json: serialized_show
          end

          protected

          def order_columns
            %w(rand published_at)
          end

          def default_order_column
            "published_at"
          end

          def component_manifest
            "proposals"
          end

          def serialized_show
            resource = find_proposal!
            pagination = proposal_pagination_meta
            Decidim::Api::RestFull::Proposals::ProposalSerializer.new(
              resource,
              params: show_serializer_params(pagination)
            ).serializable_hash
          end

          def show_serializer_params(pagination)
            {
              only: [],
              locales: available_locales,
              host: current_organization.host,
              client_id:,
              act_as:
            }.merge(pagination)
          end

          def find_proposal!
            proposal = collection.find_by("decidim_proposals_proposals.id" => resource_id)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Proposal Not Found" unless proposal

            proposal
          end

          def proposal_pagination_meta
            match = proposal_pagination_match
            {
              first: collection.ids.first,
              last: collection.ids.first,
              next: match&.next_id,
              prev: match&.previous_id,
              count: collection.ids.last
            }
          end

          def proposal_pagination_match
            model_class
              .select(proposal_pagination_select)
              .from(proposal_pagination_subquery)
              .find_by("decidim_proposals_proposals.id = ? ", resource_id)
          end

          def proposal_pagination_select
            <<~SQL.squish
              decidim_proposals_proposals.id,
              decidim_proposals_proposals.previous_id as previous_id,
              decidim_proposals_proposals.next_id as next_id
            SQL
          end

          def proposal_pagination_subquery
            "(#{proposal_windowed_query}) AS decidim_proposals_proposals"
          end

          def proposal_windowed_query
            ordered(paginated_base_scope.ransack(params[:filter]).result).to_sql
          end

          def paginated_base_scope
            collection.select(
              "decidim_proposals_proposals.id",
              "decidim_proposals_proposals.decidim_component_id",
              "decidim_proposals_proposals.published_at",
              "LAG(decidim_proposals_proposals.id) OVER (ORDER BY #{order_string}) AS previous_id",
              "LEAD(decidim_proposals_proposals.id) OVER (ORDER BY #{order_string}) AS next_id"
            )
          end

          def model_class
            Decidim::Proposals::Proposal.joins(:coauthorships)
          end

          def collection
            query = filter_for_context(model_class)
            query = query.where(decidim_component_id: params.require(:component_id)) if params.has_key? :component_id
            Rails.logger.warn "draft filtered out as filtering votes" if act_as.nil? && vote_weight_filtered?
            if act_as.nil? || vote_weight_filtered?
              query.where.not(published_at: nil)
            else
              query.where.not(published_at: nil)
                   .or(query.where("published_at IS NULL AND decidim_coauthorships.decidim_author_id = ?", act_as.id))
            end
          end

          def vote_weight_filtered?
            return false unless params.has_key?(:filter)

            params[:filter].to_unsafe_h.any? { |key, _value| key.to_s.start_with?("voted_weight") }
          end
        end
      end
    end
  end
end
