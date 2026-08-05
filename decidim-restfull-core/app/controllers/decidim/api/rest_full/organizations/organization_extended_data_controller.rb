# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Organizations
        # Exposes read/update endpoints for organization-level extended_data
        # using a dot-path API. Backed by HasExtendedData / ResourceExtendedData.
        class OrganizationExtendedDataController < ApplicationController
          include Decidim::Api::RestFull::ExtendedDataEndpoints

          before_action -> { doorkeeper_authorize! :system }

          private

          def extended_data_resource
            current_organization
          end

          def extended_data_subject_class
            ::Decidim::Organization
          end

          def extended_data_job_name
            "organization_extended_data#update"
          end
        end
      end
    end
  end
end
