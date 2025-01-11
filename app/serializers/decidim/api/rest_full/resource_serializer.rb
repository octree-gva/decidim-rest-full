# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ResourceSerializer < ApplicationSerializer
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

        link :self do |object, params|
          participatory_space = object.participatory_space
          component = object.component
          "https://#{params[:host]}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/#{participatory_space.manifest.name}/#{component.id}/#{component.manifest_name}/#{object.id}"
        end
      end
    end
  end
end
