# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Blogs
        class BlogsController < Decidim::Api::RestFull::Core::ResourcesController
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :blogs }
          before_action :authorize_read!, only: [:index, :show]
          before_action :authorize_create!, only: [:create, :create_sync]
          before_action :authorize_update!, only: [:update, :update_sync]
          before_action :authorize_destroy!, only: [:destroy, :destroy_sync]

          def index
            page = paginate(collection.includes(:component))
            payload = Decidim::Api::RestFull::Blogs::BlogSerializer.new(
              page,
              params: serializer_params
            ).serializable_hash
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(page))
          end

          def show
            @resource = find_resource!
            render_json_with_conditional_get(
              serialized_show(@resource),
              fingerprint: conditional_get_fingerprint
            )
          end

          def create
            enqueue_rest_full_api_job!("blogs/posts#create")
          end

          def create_sync
            render json: Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Blogs::BlogsOperations.new(api_execution_context, params).create!
            end
          end

          def update
            enqueue_rest_full_api_job!("blogs/posts#update")
          end

          def update_sync
            render json: Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Blogs::BlogsOperations.new(api_execution_context, params).update!
            end
          end

          def destroy
            enqueue_rest_full_api_job!("blogs/posts#destroy")
          end

          def destroy_sync
            render json: Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Blogs::BlogsOperations.new(api_execution_context, params).destroy!
            end
          end

          private

          def serialized_show(resource = find_resource!)
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
            raise Decidim::RestFull::Core::ApiException::NotFound, "Post not found" unless resource

            resource
          end

          def pagination_meta
            match = pagination_match
            bounds = collection_pagination_bounds(collection)
            {
              first: bounds[:first],
              last: bounds[:last],
              next: match&.next_id,
              prev: match&.previous_id,
              count: bounds[:count]
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

          def authorize_read!
            ability.authorize! :read, ::Decidim::Blogs::Post
          end

          def authorize_create!
            ability.authorize! :create, ::Decidim::Blogs::Post
          end

          def authorize_update!
            ability.authorize! :update, ::Decidim::Blogs::Post
          end

          def authorize_destroy!
            ability.authorize! :destroy, ::Decidim::Blogs::Post
          end
        end
      end
    end
  end
end
