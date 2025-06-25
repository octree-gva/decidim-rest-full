# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Organizations
        class OrganizationExtendedDataController < ApplicationController
          before_action -> { doorkeeper_authorize! :system }
          before_action :ensure_organization_extended_data

          before_action only: [:index] do
            authorize! :read_extended_data, ::Decidim::Organization
          end

          before_action only: [:update] do
            authorize! :update_extended_data, ::Decidim::Organization
          end

          # display an extended data
          def index
            render json: {
              data: extended_data_at_path
            }
          end

          def update
            data = params.require(:data)
            data.permit! if data.is_a?(ActionController::Parameters)

            current_organization.extended_data.update(
              data: compact_blank_recursively(
                merge_extended_data(data)
              )
            )
            current_organization.reload
            render json: {
              data: extended_data_at_path
            }
          end

          private

          def ensure_organization_extended_data
            return if current_organization.extended_data

            current_organization.create_extended_data
          end

          def extended_data_at_path
            return extended_data if object_path == "."

            object_path.split(".").reduce(extended_data) do |current, key|
              raise Decidim::RestFull::ApiException::NotFound, "key #{object_path} not found" unless current.is_a?(Hash)
              raise Decidim::RestFull::ApiException::NotFound, "key #{object_path} not found" unless current.has_key?(key)

              current[key]
            end
          end

          def merge_extended_data(obj)
            merged_extra = extended_data.deep_dup
            return merged_extra.merge(obj) if object_path == "."

            parts = object_path.split(".")
            selected = parts[..-2].reduce(merged_extra) do |current, key|
              raise Decidim::RestFull::ApiException::NotFound, "key #{object_path} not found" unless current.is_a?(Hash)

              current[key] = {} unless current.has_key?(key)
              current[key]
            end
            if selected[parts.last].is_a?(Hash)
              selected[parts.last].merge!(obj)
            else
              selected[parts.last] = obj
            end
            merged_extra
          end

          def compact_blank_recursively(hash)
            hash.each_with_object({}) do |(key, value), result|
              next if value.blank?

              result[key] = value.is_a?(Hash) ? compact_blank_recursively(value) : value
              result.delete(key) if result[key].blank?
            end
          end

          def object_path
            @object_path ||= begin
              obj_path = params.require(:object_path)
              obj_path || "."
            end
          end

          def extended_data
            current_organization.extended_data.data
          end
        end
      end
    end
  end
end
