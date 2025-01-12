module Decidim
  module Api
    module RestFull
      class ResourcesController < ApplicationController
        protected

        def order_columns
          ["rand"]
        end

        def ordered(collection)
          collection.order(order)
        end

        def default_order_column
          "rand"
        end

        def default_order_direction
          "asc"
        end

        def collection
          raise Decidim::RestFull::ApiException::NotImplemented, "#{name}#collection not implemented"
        end

        def model_class
          raise Decidim::RestFull::ApiException::NotImplemented, "#{name}#model_class not implemented"
        end

        def component_manifest
          raise Decidim::RestFull::ApiException::NotImplemented, "#{name}#component_manifest not implemented"
        end

        def order
          @order ||= begin
            ord = params.permit(:order)[:order] || default_order_column
            raise Decidim::RestFull::ApiException::BadRequest, "Unknown order #{ord}" unless [default_order_direction, *order_columns].include?(ord)

            ord == "rand" ? "RANDOM()" : { ord.to_s => order_direction }
          end
        end

        def order_direction
          @order_direction ||= begin
            ord_dir = params.permit(:order_direction)[:order_direction] || default_order_direction
            raise Decidim::RestFull::ApiException::BadRequest, "Unknown order direction #{ord_dir}" unless %w(asc desc).include?(ord_dir)

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
            match = Decidim::Component.find_by(
              participatory_space_id: space_id,
              participatory_space_type: space_model_from(space_manifest).name,
              id: component_id,
              manifest_name: component_manifest
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

        def component_id
          @component_id ||= params.require(:component_id).to_i
        end

        def resource_id
          @resource_id ||= params.require(:resource_id).to_i
        end
      end
    end
  end
end