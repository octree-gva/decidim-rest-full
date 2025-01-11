# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class BlogSerializer < ResourceSerializer
        def self.default_meta(blog_post)
          scope = blog_post.component.scope || blog_post.participatory_space.scope
          metas = {
            published: blog_post.published?
          }
          metas[:scope] = scope.id if scope
          metas
        end

        meta do |proposal, params|
          metas = default_meta(proposal)
          metas[:has_more] = params[:has_more] if params.has_key? :has_more
          metas[:next] = params[:next].id.to_s if params.has_key?(:next) && params[:next]
          metas[:prev] = params[:prev].id.to_s if params.has_key?(:prev) && params[:prev]
          metas[:count] = params[:count] if params.has_key? :count
          metas
        end

        attribute :title do |comp, params|
          translated_field(comp.title, params[:locales])
        end

        attribute :body do |comp, params|
          translated_field(comp.body, params[:locales])
        end
      end
    end
  end
end
