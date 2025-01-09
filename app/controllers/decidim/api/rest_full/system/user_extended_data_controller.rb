# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module System
        class UserExtendedDataController < ApplicationController
          before_action -> { doorkeeper_authorize! :system }
          before_action only: [:show] do
            authorize! :read_extended_data, ::Decidim::User
          end
          before_action only: [:update] do
            authorize! :update_extended_data, ::Decidim::User
          end

          # display an extended data
          def show
            render json: {
              data: extended_data_at_path
            }
          end

          def update
            data = params.require(:data)
            data.permit! if data.is_a?(ActionController::Parameters)
            user.update(
              extended_data: compact_blank_recursively(
                merge_extended_data(data)
              )
            )
            user.reload
            render json: {
              data: extended_data_at_path
            }
          end

          private

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
            user.extended_data
          end

          def user
            @user ||= Decidim::User.find(params.require(:user_id))
          end
        end
      end
    end
  end
end
