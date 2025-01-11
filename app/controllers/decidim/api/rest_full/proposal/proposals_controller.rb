# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class ProposalsController < ApplicationController
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

          private

          def ordered(collection)
            collection.order(order)
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

          def model_class
            Decidim::Proposals::Proposal.joins(:coauthorships)
          end

          def order
            @order ||= begin 
              ord = params.permit(:order)[:order] || "published_at"
              raise Decidim::RestFull::ApiException::BadRequest, "Unknown order #{ord}" unless ["published_at", "rand"].include?(ord)
              ord === "rand" ? "RANDOM()" : {"#{ord}" => order_direction}
            end
          end

          def order_direction
            @order_direction ||= begin
              ord_dir = params.permit(:order_direction)[:order_direction] || "asc"
              raise Decidim::RestFull::ApiException::BadRequest, "Unknown order direction #{ord_dir}" unless ["asc", "desc"].include?(ord_dir)
              ord_dir
            end
          end

          def space_id
            @space_id ||= params.require(:id).to_i
          end

          def space_manifest
            @space_manifest ||= params.require(:manifest_name)
          end

          def space
            @space ||= begin
              raise Decidim::RestFull::ApiException::BadRequest, "Unkown space type #{space_manifest}" unless space_manifest_names.include?(space_manifest)

              match = space_model_from(space_manifest).find_by(id: space_id, organization: current_organization)
              raise Decidim::RestFull::ApiException::NotFound, "Space not found" unless match

              match
            end
          end

          def component
            @component = begin
              raise Decidim::RestFull::ApiException::BadRequest, "Unkown component type #{component_manifest}" unless component_manifest_names.include? component_manifest

              match = Decidim::Component.find_by(
                participatory_space_id: space_id,
                participatory_space_type: space_model_from(space_manifest).name,
                id: component_id
              )
              raise Decidim::RestFull::ApiException::BadRequest, "Component not found" unless match

              match
            end
          end

          def space_model_from(manifest)
            case manifest
            when :participatory_processes
              Decidim::ParticipatoryProcess
            when :assemblies
              Decidim::Assembly
            else
              raise Decidim::RestFull::ApiException::BadRequest, "manifest not supported: #{manifest}"
            end
          end

          def space_manifest_names
            @space_manifest_names ||= Decidim.participatory_space_registry.manifests.map(&:name)
          end

          def component_manifest_names
            @component_manifest_names ||= Decidim.component_registry.manifests.map(&:name)
          end

          def component_id
            @component_id ||= params.require(:component_id).to_i
          end

          def component_manifest
            @component_manifest ||= params.require(:component_manifest_name)
          end

          def resource_id
            @resource_id ||= params.require(:resource_id).to_i
          end
        end
      end
    end
  end
end
