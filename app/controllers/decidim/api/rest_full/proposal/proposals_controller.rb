# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class ProposalsController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :read, ::Decidim::Proposals::Proposal }

          def index
            render json: Decidim::Api::RestFull::ProposalSerializer.new(
              paginate(ordered(collection)),
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
            ["rand", "published_at"]
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
