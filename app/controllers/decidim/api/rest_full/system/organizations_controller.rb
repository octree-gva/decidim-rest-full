# frozen_string_literal: true

# app/controllers/api/rest_full/system/organizations_controller.rb
module Decidim
  module Api
    module RestFull
      module System
        class OrganizationsController < ApplicationController
          before_action do
            doorkeeper_authorize! :system
            authorize! :read, ::Decidim::Organization
          end

          # List all organizations
          def index
            # Fetch organizations and paginate
            organizations = paginate(collection)
            # Render the response
            render json: serializable_hash(organizations)
          end

          # Show a single organization
          def show
            # Find the organization by ID
            organization = collection.find(params[:id])
            # Render the response
            render json: serializable_hash(organization)
          end

          private

          def serializable_hash(resource)
            OrganizationSerializer.new(
              resource,
              params: { locales: available_locales }
            ).serializable_hash
          end

          def collection
            Decidim::Organization.select(
              :id,
              :name,
              :secondary_hosts,
              :host,
              :created_at,
              :updated_at
            )
          end
        end
      end
    end
  end
end
