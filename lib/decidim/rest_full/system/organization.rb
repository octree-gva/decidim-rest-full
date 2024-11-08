# frozen_string_literal: true

module Decidim
  module RestFull
    module System
      class Organization < Grape::API
        def self.available_fields
          [:host, :name, :secondary_hosts, :meta, :id]
        end
        helpers ParamsHelper

        resource :organizations do
          desc "Available Organizations", {
            entity: "::Decidim::RestFull::Entities::OrganizationEntity",
            tags: ["system"],
            is_array: true
          }
          params do
            use :translated, :populated
          end
          paginate
          route_setting :swagger, root: "organizations"
          get "/" do
            Entities::OrganizationEntity.represent(
              paginate(Decidim::Organization.all),
              only: populated([:id]),
              locales: locales
            )
          end

          desc "Show one Organization", {
            entity: "::Decidim::RestFull::Entities::OrganizationEntity",
            tags: ["system"],
            is_array: false
          }
          params do
            use :translated, :populated
            requires :id, type: Integer
          end
          route_setting :swagger, root: "organization"
          get "/:id" do
            Entities::OrganizationEntity.represent(
              Decidim::Organization.find(params[:id]),
              only: populated(System::Organization.available_fields),
              locales: locales
            )
          end
        end
      end
    end
  end
end
