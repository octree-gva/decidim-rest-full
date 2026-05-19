# frozen_string_literal: true

module Decidim
  module RestFull
    module Blogs
      class BlogsOperations
        def initialize(execution_context, params)
          @ctx = execution_context
          @params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        end

        def create!
          component = find_component!
          authorize_manage!(component)
          post = nil
          Decidim::Blogs::Admin::CreatePost.call(build_form(component)) do
            on(:ok) { |resource| post = resource }
            on(:invalid) { raise Decidim::RestFull::Core::ApiException::BadRequest, "Post is invalid" }
          end
          serialize(post)
        end

        def update!
          post = find_post!
          authorize_manage!(post.component)
          attrs = data_attributes.permit(:published_at, title: {}, body: {}).to_h
          post.update!(attrs) if attrs.present?
          serialize(post.reload)
        end

        def destroy!
          post = find_post!
          authorize_manage!(post.component)
          serialized = serialize(post)
          post.destroy!
          serialized
        end

        private

        attr_reader :ctx, :params

        delegate :organization, :current_user, :available_locales, to: :ctx

        def data_attributes
          data = params["data"] || params[:data] || {}
          data = data.to_unsafe_h if data.respond_to?(:to_unsafe_h)
          attrs = data["attributes"] || data[:attributes] || {}
          attrs = attrs.to_unsafe_h if attrs.respond_to?(:to_unsafe_h)
          ActionController::Parameters.new(attrs)
        end

        def build_form(component)
          attrs = data_attributes.permit(:published_at, title: {}, body: {}).to_h
          Decidim::Blogs::Admin::PostForm.from_params(
            {
              title: attrs["title"] || {},
              body: attrs["body"] || {},
              published_at: attrs["published_at"],
              decidim_author_id: current_user.id
            },
            current_user:
          ).with_context(current_component: component, current_organization: organization)
        end

        def find_component!
          component_id = params.dig("data", "component_id") || params.dig(:data, :component_id) || params[:component_id]
          raise Decidim::RestFull::Core::ApiException::BadRequest, "component_id required" if component_id.blank?

          component = Decidim::Component.find_by(id: component_id, manifest_name: "blogs")
          raise Decidim::RestFull::Core::ApiException::NotFound, "Component not found" unless component
          raise Decidim::RestFull::Core::ApiException::NotFound, "Component not found" unless component.organization == organization

          component
        end

        def find_post!
          Decidim::Blogs::Post.find_by!(id: resource_id, decidim_component_id: visible_blog_component_ids)
        rescue ActiveRecord::RecordNotFound
          raise Decidim::RestFull::Core::ApiException::NotFound, "Post not found"
        end

        def resource_id
          (params[:id] || params["id"]).to_s
        end

        def visible_blog_component_ids
          Decidim::Component.where(manifest_name: "blogs", organization:).pluck(:id)
        end

        def authorize_manage!(component)
          raise Decidim::RestFull::Core::ApiException::Forbidden, "Not allowed" unless component.organization == organization
        end

        def serialize(post)
          Decidim::Api::RestFull::Blogs::BlogSerializer.new(
            post,
            params: {
              locales: available_locales,
              host: organization.host,
              act_as: current_user
            }
          ).serializable_hash
        end
      end
    end
  end
end
