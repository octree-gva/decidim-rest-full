# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ComponentSerializer < ApplicationSerializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| [:meta, :type].include? k }
        end

        def self.settings_for(comp)
          settings = comp.settings
          if settings.is_a?(String)
            JSON.parse(settings)
          else
            comp.settings.attributes
          end
        end
        attributes :manifest_name, :participatory_space_type

        attribute :participatory_space_id do |comp|
          comp.participatory_space_id.to_s
        end

        attribute :name do |comp, params|
          translated_field(comp.name, params[:locales])
        end

        attribute :global_announcement do |comp, params|
          settings = settings_for(comp)
          announcement = {}
          announcement = settings["announcement"] if settings.has_key? "announcement"
          announcement = settings["global"]["announcement"] if settings.has_key? "global"
          translated_field(announcement, params[:locales])
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |component|
          component.created_at.iso8601
        end

        attribute :updated_at do |component|
          component.updated_at.iso8601
        end

        meta do |component|
          settings = settings_for(component)
          scopes_enabled = false
          scopes_enabled = settings["scopes_enabled"] if settings.has_key? "scopes_enabled"
          {
            published: component.published_at.present?,
            scopes_enabled: scopes_enabled
          }
        end

        link :self do |object, params|
          "https://#{params[:host]}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/components/#{object.id}"
        end

        link :related do |object, params|
          space = object.participatory_space_type.constantize.find(object.participatory_space_id)
          "https://#{params[:host]}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/#{space.manifest.name}/#{space.id}/#{object.manifest_name}/#{object.id}"
        end
      end
    end
  end
end
