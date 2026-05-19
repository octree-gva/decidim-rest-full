# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Components
        class BlogComponentsController < Decidim::Api::RestFull::Components::ComponentsController
          before_action { doorkeeper_authorize! :public }
          before_action { ability.authorize! :read, ::Decidim::Component }

          def index
            query = collection.reorder(nil).ransack(params[:filter]).result
            page = paginate(in_visible_spaces(query))
            data = page.map do |component|
              Decidim::Api::RestFull::Blogs::BlogComponentSerializer.new(
                component,
                params: { only: [], locales: available_locales, host: current_organization.host, act_as: }
              ).serializable_hash[:data]
            end
            fp = Decidim::RestFull::Core::HttpCache::CollectionFingerprint.for_request(self, relation: page)
            render_json_with_conditional_get({ data: }, fingerprint: fp)
          end

          def show
            resource_id = params.require(:id).to_i
            match = collection.find(resource_id)
            payload = Decidim::Api::RestFull::Blogs::BlogComponentSerializer.new(
              match,
              params: { only: [], locales: available_locales, host: current_organization.host, act_as: }
            ).serializable_hash
            render_json_with_conditional_get(
              payload,
              fingerprint: Decidim::RestFull::Core::HttpCache::ResourceShowFingerprint.for_request(self, match)
            )
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
