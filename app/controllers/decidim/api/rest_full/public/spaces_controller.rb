# frozen_string_literal: true

# app/controllers/api/rest_full/system/organizations_controller.rb
module Decidim
  module Api
    module RestFull
      module Public
        class SpacesController < ApplicationController
          before_action { doorkeeper_authorize! :public }

          # List Space resources
          def index
            sql_queries = spaces_resources.map do |data|
              model = data[:model].constantize
              manifest = data[:manifest]
              select_transparent = if model.column_names.include? :is_transparent
                                     "#{model.table_name}.is_transparent"
                                   else
                                     "FALSE as is_transparent"
                                   end
              model.ransacker :manifest_name do |_r|
                Arel.sql("'#{manifest}'")
              end
              query = model.where(organization: current_organization).visible_for(act_as).select(
                "#{model.table_name}.created_at",
                "#{model.table_name}.updated_at",
                "#{model.table_name}.id",
                "#{model.table_name}.title",
                "#{model.table_name}.subtitle",
                "#{model.table_name}.description",
                "#{model.table_name}.short_description",
                "#{model.table_name}.private_space",
                select_transparent,
                "'#{manifest}' AS manifest_name"
              ).ransack(params[:filter])
              query.result.to_sql
            end
            union_query = sql_queries.join(" UNION ")

            results = paginate(ActiveRecord::Base.connection.exec_query(union_query).map do |result|
              Struct.new(*result.keys.map(&:to_sym)).new(*result.values)
            end)
            render json: SpaceSerializer.new(
              results,
              params: { only: [], locales: available_locales }
            ).serializable_hash
          end

          private

          def space_manifest_names
            @space_manifest_names ||= Decidim.participatory_space_registry.manifests.map(&:name)
          end

          def spaces_resources
            @spaces_resources ||= begin
              manifest_info = space_manifest_names.map do |manifest|
                manifest_data(manifest)
              end
              manifest_info.select { |data| data[:model] && Object.const_defined?(data[:model]) }
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
        end
      end
    end
  end
end
