# frozen_string_literal: true

# app/controllers/api/rest_full/system/organizations_controller.rb
module Decidim
  module Api
    module RestFull
      module System
        class OrganizationsController < ApplicationController
          before_action { doorkeeper_authorize! :system }

          # List all organizations
          def index
            # Extract only the populated fields
            allowed_fields = OrganizationSerializer.db_fields
            only_fields = populated_fields([], allowed_fields)

            # Fetch organizations and paginate
            organizations = paginate(Decidim::Organization.select(*only_fields))
            # Render the response
            render json: OrganizationSerializer.new(
              organizations,
              params: { only: only_fields, locales: available_locales },
              fields: { organization: only_fields.push(:meta) }
            ).serializable_hash
          end

          # Show a single organization
          def show
            # Extract only the populated fields
            only_fields = populated_fields(OrganizationSerializer.db_fields, OrganizationSerializer.db_fields)

            # Find the organization by ID
            organization = Decidim::Organization.find(params[:id])

            # Render the response
            render json: OrganizationSerializer.new(
              organization,
              params: { only: only_fields, locales: available_locales },
              fields: { organization: only_fields.map(&:to_sym) }
            ).serializable_hash
          end
        end
      end
    end
  end
end
