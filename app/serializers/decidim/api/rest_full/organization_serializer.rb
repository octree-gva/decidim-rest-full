# frozen_string_literal: true

# app/serializers/decidim/rest_full/organization_serializer.rb
module Decidim
  module Api
    module RestFull
      class OrganizationSerializer < ApplicationSerializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| [:meta, :id].include? k }
        end

        attributes :host, :secondary_hosts, :default_locale, :available_locales,
                   :enable_machine_translations, :enable_participatory_space_filters,
                   :badges_enabled, :rich_text_editor_in_public_views,
                   :comments_max_length, :time_zone, :users_registration_mode,
                   :user_groups_enabled,
                   :force_users_to_authenticate_before_access_organization,
                   :reference_prefix,
                   :send_welcome_notification

        attribute :name do |org, params|
          translated_field(org.name, params[:locales])
        end
        attribute :description do |org, params|
          translated_field(org.description, params[:locales])
        end

        attribute :extended_data do |org, params|
          params[:includes_extended] ? org.extended_data.data : {}
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |org|
          org.created_at.iso8601
        end

        attribute :updated_at do |org|
          org.updated_at.iso8601
        end

        meta do |org, params|
          metas = { locales: params[:locales] }
          metas[:unconfirmed_host] = org.extended_data.data["unconfirmed_host"] if org.extended_data.data["unconfirmed_host"]
          metas
        end
      end
    end
  end
end
