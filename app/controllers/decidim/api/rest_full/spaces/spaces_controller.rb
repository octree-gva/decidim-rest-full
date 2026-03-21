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

          def index
            render json: serialize_index_results
          end

          def show
            render json: serialize_space_show
          end

          private

          def serialize_index_results
            Core::SpaceSerializer.new(paginated_index_results, params: space_serializer_params).serializable_hash
          end

          def paginated_index_results
            paginate(raw_index_results.map { |row| result_struct(row) })
          end

          def raw_index_results
            ActiveRecord::Base.connection.exec_query(index_query)
          end

          def index_query
            space_sql_for(index_space_resource)
          end

          def index_space_resource
            manifest_sym = required_manifest_name.to_sym
            raise Decidim::RestFull::Core::ApiException::BadRequest, "manifest not supported: #{manifest_sym}" unless available_space?(manifest_sym)

            spaces_resources.find { |d| d[:manifest] == manifest_sym }
          end

          def serialize_search_results
            Core::SpaceSerializer.new(paginated_union_results, params: space_serializer_params).serializable_hash
          end

          def serialize_space_show
            Core::SpaceSerializer.new(space_show_query, params: space_serializer_params).serializable_hash
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
            visible_scope_for(model, act_as).select(*columns)
          end

          def space_select_columns(model, manifest, class_name)
            [
              "#{model.table_name}.created_at",
              "#{model.table_name}.updated_at",
              "#{model.table_name}.id",
              "#{model.table_name}.title",
              space_optional_column(model, "subtitle"),
              "#{model.table_name}.description",
              space_optional_column(model, "short_description"),
              space_optional_column(model, "private_space"),
              "#{model.table_name}.decidim_organization_id",
              space_transparent_column(model),
              "'#{manifest.name}' AS manifest_name",
              "'#{class_name}' AS class_name"
            ]
          end

          def space_optional_column(model, name)
            if model.column_names.include?(name)
              "#{model.table_name}.#{name}"
            else
              "NULL AS #{name}"
            end
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
            space_model_class_name(required_manifest_name)
          end

          def required_space_model
            space_model_from(required_manifest_name)
          end

          def required_space_id
            params.require(:id)
          end

          def space_show_query
            model = required_space_model
            visible_scope_for(model, act_as)
              .select(*space_show_columns(model))
              .find(required_space_id)
          end

          def space_show_columns(model)
            [
              "#{model.table_name}.created_at",
              "#{model.table_name}.updated_at",
              "#{model.table_name}.id",
              "#{model.table_name}.title",
              space_optional_column(model, "subtitle"),
              "#{model.table_name}.description",
              space_optional_column(model, "short_description"),
              "#{model.table_name}.decidim_organization_id",
              space_optional_column(model, "private_space"),
              space_transparent_column(model),
              "'#{required_manifest_name}' AS manifest_name",
              "'#{required_space_model_name}' AS class_name"
            ]
          end

          def space_manifest_names
            @space_manifest_names ||= Decidim.participatory_space_registry.manifests.map(&:name)
          end

          def spaces_resources
            @spaces_resources ||= available_space_manifest_names.map do |manifest|
              { model: space_model_class_name(manifest), manifest: }
            end
          end
        end
      end
    end
  end
end
