# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Helpers
        module ResourceLinksHelper
          def link_infos_from_resource(resource)
            component = resource.component
            space = resource.participatory_space
            {
              component_id: component.id.to_s,
              component_manifest: component.manifest_name,
              space_id: space.id.to_s,
              space_manifest: space.manifest.name,
              resource_id: resource.id.to_s
            }
          end

          def link_for_resource(host, link_infos, resource_id)
            "#{link_for_collection(host, link_infos)}/#{resource_id}"
          end

          def link_for_collection(host, link_infos)
            "https://#{host}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/#{link_infos[:space_manifest]}/#{link_infos[:space_id]}/#{link_infos[:component_id]}/#{link_infos[:component_manifest]}"
          end
        end
      end
    end
  end
end
