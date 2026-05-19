# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Blogs
        class BlogSerializer < ::Decidim::Api::RestFull::Core::ResourceSerializer
          extend ::Decidim::Api::RestFull::Core::Helpers::ResourceLinksHelper

          def self.default_meta(blog_post)
            scope = blog_post.component.scope || blog_post.participatory_space.scope
            metas = {
              published: blog_post.published?
            }
            metas[:scope] = scope.id if scope
            metas
          end

          link :next, if: (proc do |_object, params|
                             params.has_key?(:next) && params[:next]
                           end) do |object, params|
            next_id = params[:next]
            infos = link_infos_from_resource(object)
            {
              href: link_for_resource(params[:host], infos, next_id),
              title: "Next post",
              rel: "resource",
              meta: {
                **infos,
                resource_id: next_id.to_s,
                action_method: "GET"
              }
            }
          end

          link :prev, if: (proc do |_object, params|
                             params.has_key?(:prev) && params[:prev]
                           end) do |object, params|
            prev_id = params[:prev]
            infos = link_infos_from_resource(object)
            {
              href: link_for_resource(params[:host], infos, prev_id),
              title: "Previous post",
              rel: "resource",
              meta: {
                **infos,
                resource_id: prev_id.to_s,
                action_method: "GET"
              }
            }
          end

          meta do |blog_post, _params|
            default_meta(blog_post)
          end

          attribute :title do |comp, params|
            translated_field(comp.title, params[:locales])
          end

          attribute :body do |comp, params|
            translated_field(comp.body, params[:locales])
          end

          attribute :published_at, &:published_at
        end
      end
    end
  end
end
