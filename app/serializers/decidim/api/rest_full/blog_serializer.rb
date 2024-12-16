# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class BlogSerializer < ApplicationSerializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| [:meta, :type].include? k }
        end

        def self.default_meta(blog_post)
          scope = blog_post.component.scope || blog_post.participatory_space.scope
          metas = {
            published: blog_post.published?
          }
          metas[:scope] = scope.id if scope
          metas
        end

        has_one :space do |blog_post, _params|
          blog_post.participatory_space
        end

        has_one :component, serializer: (proc do |component, _params|
          "Decidim::Api::RestFull::#{component.manifest_name.to_s.singularize.camelize}ComponentSerializer".constantize
        end) do |blog_post, _params|
          blog_post.component
        end

        attribute :title do |comp, params|
          translated_field(comp.title, params[:locales])
        end

        attribute :body do |comp, params|
          translated_field(comp.body, params[:locales])
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |blog_post|
          blog_post.created_at.iso8601
        end

        attribute :updated_at do |blog_post|
          blog_post.updated_at.iso8601
        end

        meta do |blog_post|
          default_meta(blog_post)
        end

        link :self do |object, params|
          participatory_space = object.participatory_space
          component = object.component
          "https://#{params[:host]}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/#{participatory_space.manifest.name}/#{component.id}/#{component.manifest_name}/#{object.id}"
        end
      end
    end
  end
end
