# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Components
        class BlogComponentsController < Decidim::Api::RestFull::Components::ComponentsController
          before_action { doorkeeper_authorize! :public }
          before_action { ability.authorize! :read, ::Decidim::Component }

          def index
            query = find_components(collection)
            query = query.reorder(nil).ransack(params[:filter])
            data = paginate(ActiveRecord::Base.connection.exec_query(query.result.to_sql).map do |result|
              result = Struct.new(*result.keys.map(&:to_sym)).new(*result.values)
              Decidim::Api::RestFull::BlogComponentSerializer.new(
                result,
                params: { only: [], locales: available_locales, host: current_organization.host, act_as: act_as }
              ).serializable_hash[:data]
            end)
            render json: { data: data }
          end

          def show
            resource_id = params.require(:id).to_i
            match = collection.find(resource_id)

            render json: Decidim::Api::RestFull::BlogComponentSerializer.new(
              match,
              params: { only: [], locales: available_locales, host: current_organization.host, act_as: act_as }
            ).serializable_hash
          end

          protected

          def blog
            @blog ||= collection.find(params.require(:resource_id))
          end

          def blog_component
            @blog_component ||= blog.component
          end

          def order_columns
            %w(rand published_at)
          end

          def default_order_column
            "published_at"
          end

          def component_manifest
            "blogs"
          end

          def model_class
            Decidim::Component
          end

          def collection
            model_class.where(manifest_name: "blogs")
          end
        end
      end
    end
  end
end
