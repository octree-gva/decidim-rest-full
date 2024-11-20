# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ComponentSerializer < ApplicationSerializer
        include ::JSONAPI::Serializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| [:meta, :type].include? k }
        end

        attribute :manifest_name, &:manifest_name

        attribute :title do |comp, params|
          translated_field(comp.title, params[:locales])
        end

        attribute :global_annoucement do |comp, params|
          translated_field(JSON.parse(comp.settings)["global"]["annoucement"], params[:locales])
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
