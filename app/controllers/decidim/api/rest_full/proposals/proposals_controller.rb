# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposals
        class ProposalsController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :read, ::Decidim::Proposals::Proposal }
          class CurrentUser < ActiveSupport::CurrentAttributes
            attribute :user
          end
          before_action { CurrentUser.user = current_user }
          def index
            query = collection.ransack(params[:filter])

            results = query.result
            render json: Decidim::Api::RestFull::ProposalSerializer.new(
              paginate(ordered(results)),
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                client_id: client_id,
                act_as: act_as
              }
            ).serializable_hash
          end

          def show
            resource = collection.find_by("decidim_proposals_proposals.id" => resource_id)
            raise Decidim::RestFull::ApiException::NotFound, "Proposal Not Found" unless resource

            subquery = ordered(collection.select(
              "decidim_proposals_proposals.id",
              "decidim_proposals_proposals.decidim_component_id",
              "decidim_proposals_proposals.published_at",
              "LAG(decidim_proposals_proposals.id) OVER (ORDER BY #{order_string}) AS previous_id",
              "LEAD(decidim_proposals_proposals.id) OVER (ORDER BY #{order_string}) AS next_id"
            ).ransack(params[:filter]).result).to_sql
            aliased_subquery = "(#{subquery}) AS decidim_proposals_proposals"
            select_for_pagination = <<~SQL.squish
              decidim_proposals_proposals.id,
              decidim_proposals_proposals.previous_id as previous_id,
              decidim_proposals_proposals.next_id as next_id
            SQL
            pagination_match = model_class.select(select_for_pagination).from(aliased_subquery).find_by(
              "decidim_proposals_proposals.id = ? ", resource_id
            )
            next_item = pagination_match.next_id
            prev_item = pagination_match.previous_id
            pagination_match.previous_id
            first_item = collection.ids.first
            last_item = collection.ids.last

            render json: Decidim::Api::RestFull::ProposalSerializer.new(
              resource,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                client_id: client_id,
                act_as: act_as,
                first: first_item,
                last: first_item,
                next: next_item,
                prev: prev_item,
                count: last_item
              }
            ).serializable_hash
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
