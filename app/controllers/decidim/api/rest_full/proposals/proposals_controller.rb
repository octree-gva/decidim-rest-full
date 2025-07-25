# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposals
        class ProposalsController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :read, ::Decidim::Proposals::Proposal }

          def index
            add_state_filter!
            add_vote_weight_filter! if current_user && Object.const_defined?("Decidim::DecidimAwesome") && Decidim::DecidimAwesome.enabled?(:weighted_proposal_voting)

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
            add_state_filter!
            resource = collection.find_by("decidim_proposals_proposals.id" => resource_id)
            raise Decidim::RestFull::ApiException::NotFound, "Proposal Not Found" unless resource

            add_vote_weight_filter! if current_user && Object.const_defined?("Decidim::DecidimAwesome") && Decidim::DecidimAwesome.enabled?(:weighted_proposal_voting)
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

            Time.zone.now
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

          def add_state_filter!
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

          def add_vote_weight_filter!
            Decidim::Proposals::Proposal.ransacker :voted_weight do |_r|
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
end
