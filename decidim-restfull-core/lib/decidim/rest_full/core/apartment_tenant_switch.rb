# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Optional ros-apartment: switch tenant by host for collection queries.
      # Request tenant is held by Decidim::Apartment::Elevator (insert_before CurrentOrganization).
      # Missing tenant/org → nil (caller maps that to 404/empty). Never Organization.first.
      module ApartmentTenantSwitch
        module_function

        def call(host)
          return yield unless Gem.loaded_specs.has_key?("ros-apartment")

          key = Decidim::Apartment::DistributionKey.for_host(host)
          return unless key

          key.switch { yield }
        end
      end
    end
  end
end
