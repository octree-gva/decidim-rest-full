# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Public
        class ComponentsController < ApplicationController
          before_action { doorkeeper_authorize! :public }

          # Index all components
          def index
            query = if visible_spaces.size.positive?
                      # Query components that are published in a visible space.
                      first_visible_space = visible_spaces.first
                      query_manifest = Decidim::Component.all
                      query = query_manifest.where(**first_visible_space)
                      visible_spaces[1..].each do |visible_space|
                        query = query.or(query_manifest.where(**visible_space))
                      end
                      query.select(:created_at, :updated_at, :id, "name AS title", :manifest_name, :settings)
                    else
                      model.where("1=0")
                    end

            query = query.reorder(nil).ransack(params[:filter])
            results = paginate(ActiveRecord::Base.connection.exec_query(query.result.to_sql).map do |result|
              Struct.new(*result.keys.map(&:to_sym)).new(*result.values)
            end)
            render json: ComponentSerializer.new(
              results,
              params: { only: [], locales: available_locales }
            ).serializable_hash
          end

          private

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
