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
            raise "link_for_resource: missing host" unless host

            "#{link_for_collection(host, link_infos)}/#{resource_id}"
          end

          def link_for_collection(host, link_infos)
            raise "link_for_collection: missing host" unless host

            link_join(host, link_infos[:component_manifest])
          end

          def link_join(host, *url_parts)
            raise "link_join: missing host" unless host

            normalized_host = host.to_s.end_with?("/") ? host[0..-1] : host
            portions = url_parts.map do |part|
              part.to_s.split("/").first
            end
            path_prefix = portions.empty? ? "" : "/"
            "https://#{normalized_host}/api/rest_full/v#{Decidim::RestFull.major_minor_version}#{path_prefix}#{portions.join("/")}"
          end
        end
      end
    end
  end
end
