# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class SpaceSerializer < ApplicationSerializer
        include ::JSONAPI::Serializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| [:id, :meta, :visibility, :components, :type].include? k }
        end

        attribute :manifest_name, &:manifest_name

        attribute :title do |space, params|
          translated_field(space.title, params[:locales])
        end

        attribute :subtitle do |space, params|
          translated_field(space.subtitle, params[:locales])
        end

        attribute :short_description do |space, params|
          translated_field(space.short_description, params[:locales])
        end

        attribute :description do |space, params|
          translated_field(space.description, params[:locales])
        end

        attribute :visibility do |space, _params|
          is_private = space.private_space if space.respond_to?(:private_space)
          is_transparent = space.is_transparent if space.respond_to?(:is_transparent)
          if is_private
            "private"
          elsif is_transparent
            "transparent"
          else
            "public"
          end
        end

        attribute :components do
          []
        end

        attribute :meta do |_org, params|
          {
            populated: params[:only],
            locales: params[:locales]
          }
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |org|
          org.created_at.iso8601
        end

        attribute :updated_at do |org|
          org.updated_at.iso8601
        end
      end
    end
  end
end
