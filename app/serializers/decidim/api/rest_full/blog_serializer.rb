# frozen_string_literal: true

require_relative "helpers/resource_links_helper"
module Decidim
  module Api
    module RestFull
      class BlogSerializer < ResourceSerializer
        extend Helpers::ResourceLinksHelper

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
            title: "Next Blog Post",
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
            title: "Previous Blog Post",
            rel: "resource",
            meta: {
              **infos,
              resource_id: prev_id.to_s,
              action_method: "GET"
            }
          }
        end

        meta do |proposal, _params|
          default_meta(proposal)
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
