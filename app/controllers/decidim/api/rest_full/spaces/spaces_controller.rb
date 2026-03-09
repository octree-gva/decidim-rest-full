# frozen_string_literal: true

# app/controllers/api/rest_full/system/organizations_controller.rb
module Decidim
  module Api
    module RestFull
      module Spaces
        class SpacesController < ApplicationController
          before_action { doorkeeper_authorize! :public }
          before_action { ability.authorize! :read, ::Decidim::ParticipatorySpaceManifest }

          def search
            render json: serialize_search_results
          end

          def show
            render json: serialize_space_show
          end

          private

          def serialize_search_results
            SpaceSerializer.new(paginated_union_results, params: space_serializer_params).serializable_hash
          end

          def serialize_space_show
            SpaceSerializer.new(space_show_query, params: space_serializer_params).serializable_hash
          end

          def space_serializer_params
            { only: [], locales: available_locales, host: current_organization.host }
          end

          def paginated_union_results
            paginate(raw_union_results.map { |row| result_struct(row) })
          end

          def raw_union_results
            ActiveRecord::Base.connection.exec_query(union_query)
          end

          def union_query
            spaces_resources.map { |data| space_sql_for(data) }.join(" UNION ")
          end

          def space_sql_for(data)
            model = data[:model].constantize
            columns = space_select_columns(model, data[:manifest], data[:model])
            model_query(model, columns).ransack(params[:filter]).result.to_sql
          end

          def model_query(model, columns)
            model.where(organization: current_organization).visible_for(act_as).select(*columns)
          end

          def space_select_columns(model, manifest, class_name)
            [
              "#{model.table_name}.created_at",
              "#{model.table_name}.updated_at",
              "#{model.table_name}.id",
              "#{model.table_name}.title",
              "#{model.table_name}.subtitle",
              "#{model.table_name}.description",
              "#{model.table_name}.short_description",
              "#{model.table_name}.private_space",
              "#{model.table_name}.decidim_organization_id",
              space_transparent_column(model),
              "'#{manifest.name}' AS manifest_name",
              "'#{class_name}' AS class_name"
            ]
          end

          def space_transparent_column(model)
            if model.column_names.include?("is_transparent")
              "#{model.table_name}.is_transparent"
            else
              "FALSE as is_transparent"
            end
          end

          def result_struct(row)
            Struct.new(*row.keys.map(&:to_sym)).new(*row.values)
          end

          def required_manifest_name
            params.require(:manifest_name)
          end

          def required_space_model_name
            manifest_data(required_manifest_name)[:model]
          end

          def required_space_model
            name = required_space_model_name
            raise Decidim::RestFull::ApiException::BadRequest, "manifest not supported: #{required_manifest_name}" unless Object.const_defined?(name)

            name.constantize
          end

          def required_space_id
            params.require(:id)
          end

          def space_show_query
            model = required_space_model
            model.where(organization: current_organization)
                 .visible_for(act_as)
                 .select(*space_show_columns(model))
                 .find(required_space_id)
          end

          def space_show_columns(model)
            [
              "#{model.table_name}.created_at",
              "#{model.table_name}.updated_at",
              "#{model.table_name}.id",
              "#{model.table_name}.title",
              "#{model.table_name}.subtitle",
              "#{model.table_name}.description",
              "#{model.table_name}.short_description",
              "#{model.table_name}.decidim_organization_id",
              "#{model.table_name}.private_space",
              space_transparent_column(model),
              "'#{required_manifest_name}' AS manifest_name",
              "'#{required_space_model_name}' AS class_name"
            ]
          end

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
              { model: "Decidim::ParticipatoryProcess", manifest: }
            when :assemblies
              { model: "Decidim::Assembly", manifest: }
            else
              raise Decidim::RestFull::ApiException::BadRequest, "manifest not supported: #{manifest}"
            end
          end
        end
      end
    end
  end
end
