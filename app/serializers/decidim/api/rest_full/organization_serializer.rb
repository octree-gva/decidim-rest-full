# frozen_string_literal: true

# app/serializers/decidim/rest_full/organization_serializer.rb
module Decidim
  module Api
    module RestFull
      class OrganizationSerializer < ApplicationSerializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| [:meta, :id].include? k }
        end

        attributes :host, :secondary_hosts

        attribute :name do |org, params|
          translated_field(org.name, params[:locales])
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |org|
          org.created_at.iso8601
        end

        attribute :updated_at do |org|
          org.updated_at.iso8601
        end

        meta do |_org, params|
          {
            locales: params[:locales]
          }
        end
      end
    end
  end
end
