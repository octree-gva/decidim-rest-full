# frozen_string_literal: true

require_relative "helpers/resource_links_helper"

module Decidim
  module Api
    module RestFull
      class ResourceSerializer < ApplicationSerializer
        extend Helpers::ResourceLinksHelper

        has_one :space do |resource, _params|
          resource.participatory_space
        end

        has_one :component, serializer: (proc do |component, _params|
          "Decidim::Api::RestFull::#{component.manifest_name.to_s.singularize.camelize}ComponentSerializer".constantize
        end) do |resource, _params|
          resource.component
        end

        # Format timestamps to ISO 8601
        attribute :created_at do |resource|
          resource.created_at.iso8601
        end

        attribute :updated_at do |resource|
          resource.updated_at.iso8601
        end

        link :related do |object, params|
          infos = link_infos_from_resource(object)
          {
            href: "https://#{params[:host]}/public/components/#{infos[:component_id]}",
            title: object.component.name[I18n.locale.to_s] || "Related component",
            rel: "resource",
            meta: {
              space_id: infos[:space_id],
              space_manifest: infos[:space_manifest],
              component_id: infos[:component_id],
              component_manifest: infos[:component_manifest],
              action_method: "GET"
            }
          }
        end

        link :self do |object, params|
          infos = link_infos_from_resource(object)
          {
            href: link_for_resource(params[:host], infos, object.id),
            title: "#{infos[:component_manifest].titleize} Details",
            rel: "resource",
            meta: {
              **infos,
              action_method: "GET"
            }
          }
        end

        link :collection do |object, params|
          infos = link_infos_from_resource(object)
          {
            href: link_for_collection(params[:host], infos),
            title: "#{infos[:component_manifest].titleize} List",
            rel: "resource",
            meta: {
              **infos,
              action_method: "GET"
            }
          }
        end
      end
    end
  end
end
