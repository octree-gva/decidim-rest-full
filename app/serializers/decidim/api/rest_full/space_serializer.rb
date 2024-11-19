# frozen_string_literal: true

# app/serializers/decidim/rest_full/space_serializer.rb
module Decidim
  module Api
    module RestFull
      class SpaceSerializer
        include JSONAPI::Serializer

        set_type :space # Matches the root element "space"
        set_key_transform :camel_lower

        attributes :id, :manifest, :created_at, :updated_at, :published_at

        # Title, subtitle, description, and short_description use the TranslatedSerializer
        attribute :title do |space, params|
          TranslatedSerializer.new(space.title.with_indifferent_access, params).serializable_hash[:data][:attributes]
        end

        attribute :subtitle do |space, params|
          TranslatedSerializer.new(space.subtitle.with_indifferent_access, params).serializable_hash[:data][:attributes]
        end

        attribute :description do |space, params|
          TranslatedSerializer.new(space.description.with_indifferent_access, params).serializable_hash[:data][:attributes]
        end

        attribute :short_description do |space, params|
          TranslatedSerializer.new(space.short_description.with_indifferent_access, params).serializable_hash[:data][:attributes]
        end

        # Meta uses the MetaSerializer
        attribute :meta do |_space, params|
          MetaSerializer.new({ populated: params[:only], locales: params[:locales] }).serializable_hash[:data][:attributes]
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |space|
          space.created_at.iso8601
        end

        attribute :updated_at do |space|
          space.updated_at.iso8601
        end

        attribute :published_at do |space|
          space.published_at.iso8601 if space.published_at.present?
        end
      end
    end
  end
end
