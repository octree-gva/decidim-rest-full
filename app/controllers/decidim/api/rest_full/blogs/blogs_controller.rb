# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Blogs
        class BlogsController < ResourcesController
          before_action { doorkeeper_authorize! :blogs }
          before_action { ability.authorize! :read, ::Decidim::Blogs::Post }

          def index
            render json: serialized_index
          end

          def show
            render json: serialized_show
          end

          private

          def serialized_index
            Decidim::Api::RestFull::Blogs::BlogSerializer.new(
              paginate(collection),
              params: serializer_params
            ).serializable_hash
          end

          def serialized_show
            resource = find_resource!
            pagination = pagination_meta
            Decidim::Api::RestFull::Blogs::BlogSerializer.new(
              resource,
              params: serializer_params.merge(pagination)
            ).serializable_hash
          end

          def order_columns
            %w(rand published_at)
          end

          def collection
            query = filter_for_context(model_class.order(published_at: :asc))
            query = query.where(decidim_component_id: params.require(:component_id)) if params.has_key? :component_id

            now = Time.zone.now
            if act_as.nil?
              query.where(published_at: ...now)
            else
              query.where("published_at <= ? OR (published_at > ? AND decidim_author_id = ?)", now, now, act_as.id)
            end
            ordered(query)
          end

          def serializer_params
            {
              only: [],
              locales: available_locales,
              host: current_organization.host,
              act_as:
            }
          end

          def find_resource!
            resource = collection.find_by(id: resource_id)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Blog Post Not Found" unless resource

            resource
          end

          def pagination_meta
            match = pagination_match
            {
              first: collection.ids.first,
              last: collection.ids.last,
              next: match&.next_id,
              prev: match&.previous_id,
              count: collection.ids.last
            }
          end

          def pagination_match
            subquery = collection
                       .select(:id, "LAG(id) OVER (ORDER BY #{order_string}) AS previous_id", "LEAD(id) OVER (ORDER BY #{order_string}) AS next_id")
                       .to_sql
            aliased = "(#{subquery}) AS subquery"
            model_class
              .select("subquery.id, subquery.previous_id as previous_id, subquery.next_id as next_id")
              .from(aliased)
              .find_by("subquery.id = ? ", resource_id)
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
