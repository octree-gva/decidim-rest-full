# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class SpaceSerializer < ApplicationSerializer
        def self.db_fields
          (attributes_to_serialize.keys || []).reject { |k| [:id, :meta, :visibility, :components, :type].include? k }
        end

        attribute :manifest_name, &:manifest_name

        attribute :participatory_space_type, &:class_name

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

        has_many :components, serializer: (proc do |component, _params|
          "Decidim::Api::RestFull::#{component.manifest_name.to_s.singularize.camelize}ComponentSerializer".constantize
        end), meta: (proc do |space, _params|
          { count: Decidim::Component.where(participatory_space_type: space.class_name, participatory_space_id: space.id).count }
        end), links: {
          self: lambda { |object, params|
            {
              href: "https://#{params[:host]}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/public/components?filter[participatory_space_type_eq]=#{object.class_name}&filter[participatory_space_id_eq]=#{object.id}",
              title: "Component list for this space",
              rel: "resource",
              meta: {
                space_manifest: object.manifest_name,
                space_id: object.id.to_s,
                action_method: "GET"
              }
            }
          }
        } do |space, _params|
          Decidim::Component.where(
            participatory_space_type: space.class_name,
            participatory_space_id: space.id
          ).limit(50)
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |org|
          org.created_at.iso8601
        end

        attribute :updated_at do |org|
          org.updated_at.iso8601
        end

        link :self do |space, params|
          {
            href: "https://#{params[:host]}/public/#{space.manifest_name}/#{space.id}",
            title: space.title[I18n.locale.to_s] || "Space Details",
            rel: "resource",
            meta: {
              space_id: space.id.to_s,
              space_manifest: space.manifest_name,
              action_method: "GET"
            }
          }
        end

        link :related do |space, params|
          organization = Decidim::Organization.find(space.decidim_organization_id.to_i)
          {
            href: "https://#{params[:host]}/system/organizations/#{organization.id}",
            title: organization.name[I18n.locale.to_s] || "Organization Details",
            rel: "resource",
            meta: {
              action_method: "GET"
            }
          }
        end
      end
    end
  end
end
