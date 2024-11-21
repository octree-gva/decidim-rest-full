# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Public
        class ComponentsController < ApplicationController
          before_action { doorkeeper_authorize! :public }

          # Index all components
          def index
            query = find_components(Decidim::Component.all)
            query = query.reorder(nil).ransack(params[:filter])
            data = paginate(ActiveRecord::Base.connection.exec_query(query.result.to_sql).map do |result|
              result = Struct.new(*result.keys.map(&:to_sym)).new(*result.values)
              serializer = "Decidim::Api::RestFull::#{result.manifest_name.singularize.camelize}ComponentSerializer".constantize
              serializer.new(result, params: { only: [], locales: available_locales, host: current_organization.host, act_as: act_as }).serializable_hash[:data]
            end)

            render json: { data: data }
          end

          def show
            component_id = params.require(:id).to_i
            component = find_components(Decidim::Component.where(id: component_id)).first!
            serializer = "Decidim::Api::RestFull::#{component.manifest_name.singularize.camelize}ComponentSerializer".constantize

            render json: serializer.new(
              component,
              params: { only: [], locales: available_locales, host: current_organization.host, act_as: act_as }
            ).serializable_hash
          end

          private

          ##
          # Find components that are published in a visible space.
          # exemple: if the user has no view on Decidim::Assembly#2
          #          THEN should not be able to query any Decidim::Assembly#2 components
          def find_components(context = Decidim::Component.all)
            if visible_spaces.size.positive?
              first_visible_space = visible_spaces.first
              query_manifest = context
              query = query_manifest.where(**first_visible_space)
              visible_spaces[1..].each do |visible_space|
                query = query.or(query_manifest.where(**visible_space))
              end
              query
            else
              context.where("1=0")
            end
          end

          ##
          # All the spaces (assembly, participatory process) visible
          # for the current actor.
          # @returns participatory_space_type, participatory_space_id values
          def visible_spaces
            @visible_spaces ||= begin
              spaces = space_manifest_names.map do |space|
                data = manifest_data(space)
                query = data[:model].constantize.visible_for(act_as).where(organization: current_organization)
                {
                  participatory_space_type: data[:model],
                  participatory_space_id: query.ids
                }
              end
              spaces.reject do |space_params|
                space_params[:participatory_space_id].empty?
              end
            end
          end

          def manifest_data(manifest)
            case manifest
            when :participatory_processes
              { model: "Decidim::ParticipatoryProcess", manifest: manifest }
            when :assemblies
              { model: "Decidim::Assembly", manifest: manifest }
            else
              raise Decidim::RestFull::ApiException::BadRequest, "manifest not found: #{manifest}"
            end
          end

          def space_manifest_names
            @space_manifest_names ||= Decidim.participatory_space_registry.manifests.map(&:name)
          end

          def component_manifest_names
            @component_manifest_names ||= Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }
          end
        end
      end
    end
  end
end
