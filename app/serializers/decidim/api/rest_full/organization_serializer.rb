# frozen_string_literal: true

# app/serializers/decidim/rest_full/organization_serializer.rb
module Decidim
  module Api
    module RestFull
      class OrganizationSerializer
        include ::JSONAPI::Serializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| k == :meta }
        end

        def self.translated_field(translated_value, locales)
          translated_value.select { |key| locales.include?(key.to_sym) }
        end

        attributes :id, :host, :secondary_hosts

        attribute :name do |org, params|
          translated_field(org.name, params[:locales])
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
