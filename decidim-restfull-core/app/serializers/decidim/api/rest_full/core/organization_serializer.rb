# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        # Serializer for organizations, exposing main configuration fields,
        # translated attributes and optional extended_data for the REST API.
        class OrganizationSerializer < ApplicationSerializer
          def self.db_fields
            (attributes_to_serialize.keys || []).reject { |k| [:meta, :id].include? k }
          end

          attributes :host, :secondary_hosts, :default_locale, :available_locales,
                     :enable_machine_translations,
                     :badges_enabled, :rich_text_editor_in_public_views,
                     :comments_max_length, :time_zone, :users_registration_mode,
                     :force_users_to_authenticate_before_access_organization,
                     :reference_prefix,
                     :send_welcome_notification

          # Removed in Decidim 0.32; keep API keys for contract stability.
          attribute :enable_participatory_space_filters do |_org|
            false
          end
          attribute :user_groups_enabled do |_org|
            false
          end

          attribute :name do |org, params|
            translated_field(org.name, params[:locales])
          end
          attribute :description do |org, params|
            translated_field(org.description, params[:locales])
          end

          attribute :extended_data do |org, params|
            params[:includes_extended] ? org.extended_data_hash : {}
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
            unconfirmed = org.extended_data_hash["unconfirmed_host"]
            metas[:unconfirmed_host] = unconfirmed if unconfirmed
            metas
          end
        end
      end
    end
  end
end
