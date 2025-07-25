# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Blogs
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

            blog_table = model_class.table_name
            subquery = ordered(collection.select(
              "#{blog_table}.id",
              "#{blog_table}.decidim_component_id",
              "#{blog_table}.published_at",
              "LAG(#{blog_table}.id) OVER (ORDER BY #{order_string}) AS previous_id",
              "LEAD(#{blog_table}.id) OVER (ORDER BY #{order_string}) AS next_id"
            ).ransack(params[:filter]).result).to_sql
            aliased_subquery = "(#{subquery}) AS #{blog_table}"
            select_for_pagination = <<~SQL.squish
              #{blog_table}.id,
              #{blog_table}.previous_id as previous_id,
              #{blog_table}.next_id as next_id
            SQL
            model_class.select(select_for_pagination).from(aliased_subquery).find_by(
              "#{blog_table}.id = ? ", resource_id
            )

            subquery = collection.select(
              :id,
              "LAG(id) OVER (ORDER BY #{order_string}) AS previous_id",
              "LEAD(id) OVER (ORDER BY #{order_string}) AS next_id"
            ).to_sql
            aliased_subquery = "(#{subquery}) AS subquery"

            pagination_match = model_class.select("subquery.id, subquery.previous_id as previous_id, subquery.next_id as next_id").from(aliased_subquery).find_by(
              "subquery.id = ? ", resource_id
            )

            next_item = pagination_match.next_id
            prev_item = pagination_match.previous_id
            pagination_match.previous_id
            first_item = collection.ids.first
            last_item = collection.ids.last

            render json: Decidim::Api::RestFull::BlogSerializer.new(
              resource,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as,
                first: first_item,
                last: first_item,
                next: next_item,
                prev: prev_item,
                count: last_item
              }
            ).serializable_hash
          end

          private

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
