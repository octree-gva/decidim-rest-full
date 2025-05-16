# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Components
        class ComponentsController < ApplicationController
          before_action { doorkeeper_authorize! :public }
          before_action { ability.authorize! :read, ::Decidim::Component }

          def search
            Decidim::Component.ransacker :id do |_r|
              Arel.sql('CAST("decidim_components"."id" AS VARCHAR)')
            end
            query = Decidim::Component.all
            query = query.reorder(nil).ransack(params[:filter])
            data = paginate(ActiveRecord::Base.connection.exec_query(in_visible_spaces(query.result).to_sql).map do |result|
              result = Struct.new(*result.keys.map(&:to_sym)).new(*result.values)
              serializer = "Decidim::Api::RestFull::#{result.manifest_name.singularize.camelize}ComponentSerializer".constantize
              serializer.new(
                result,
                params: {
                  only: [],
                  locales: available_locales,
                  host: current_organization.host,
                  act_as: act_as,
                  client_id: client_id
                }
              ).serializable_hash[:data]
            end)

            render json: { data: data }
          end

          def show
            component_id = params.require(:id).to_i
            component = in_visible_spaces(Decidim::Component.where(id: component_id)).first
            raise Decidim::RestFull::ApiException::NotFound, "Component not found" unless component

            serializer = "Decidim::Api::RestFull::#{component.manifest_name.singularize.camelize}ComponentSerializer".constantize

            render json: serializer.new(
              component,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as,
                client_id: client_id
              }
            ).serializable_hash
          end

          private

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
