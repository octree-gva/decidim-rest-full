# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class ProposalsController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :read, ::Decidim::Proposals::Proposal }

          def index
            if current_user && Object.const_defined?("Decidim::DecidimAwesome") && Decidim::DecidimAwesome.enabled?(:weighted_proposal_voting)
              Decidim::Proposals::Proposal.ransacker :voted_weight do |_r|
                Arel.sql(<<~SQL.squish
                  (
                    SELECT
                      COALESCE(CAST(tweight.weight AS VARCHAR), '1') AS weight
                    FROM #{Decidim::Proposals::ProposalVote.table_name} AS tvote
                    LEFT JOIN #{Decidim::DecidimAwesome::VoteWeight.table_name} AS tweight
                      ON tvote.id = tweight.proposal_vote_id
                    WHERE
                      tvote.decidim_proposal_id = decidim_proposals_proposals.id AND
                      tvote.decidim_author_id = #{current_user.id.to_i}
                    LIMIT 1
                  )
                SQL
                        )
              end

            end
            query = ordered(collection).ransack(params[:filter])
            results = query.result

            render json: Decidim::Api::RestFull::ProposalSerializer.new(
              paginate(results),
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as
              }
            ).serializable_hash
          end

          def show
            resource = collection.find_by("decidim_proposals_proposals.id" => resource_id)
            raise Decidim::RestFull::ApiException::NotFound, "Proposal Not Found" unless resource

            next_item = collection.where("published_at > ? AND decidim_proposals_proposals.id != ?", resource.published_at, resource_id).first
            first_item = collection.first

            render json: Decidim::Api::RestFull::ProposalSerializer.new(
              resource,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as,
                has_more: next_item.present?,
                next: next_item || first_item,
                count: collection.count
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
            query = model_class.where(component: component)
            now = Time.zone.now
            if act_as.nil?
              query.where("published_at" => ...now)
            else
              query.where("published_at <= ? OR (published_at is NULL AND decidim_coauthorships.decidim_author_id = ?)", now, act_as.id)
            end
          end
        end
      end
    end
  end
end
