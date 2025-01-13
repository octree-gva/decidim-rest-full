# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Blog
        class BlogsController < ResourcesController
          before_action { doorkeeper_authorize! :blogs }
          before_action { ability.authorize! :read, ::Decidim::Blogs::Post }

          def index
            render json: Decidim::Api::RestFull::BlogSerializer.new(
              paginate(collection),
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as
              }
            ).serializable_hash
          end

          def show
            resource = collection.find(resource_id)
            raise Decidim::RestFull::ApiException::NotFound, "Blog Post Not Found" unless resource

            next_item = collection.where("published_at > ? AND id != ?", resource.published_at, resource_id).first
            first_item = collection.first

            render json: Decidim::Api::RestFull::BlogSerializer.new(
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

          def collection
            query = model_class.order(published_at: :asc).where(component: component)
            now = Time.zone.now
            if act_as.nil?
              query.where(published_at: ...now)
            else
              query.where("published_at <= ? OR (published_at > ? AND decidim_author_id = ?)", now, now, act_as.id)
            end
          end

          def model_class
            Decidim::Blogs::Post
          end

          def component_manifest
            "blogs"
          end
        end
      end
    end
  end
end
