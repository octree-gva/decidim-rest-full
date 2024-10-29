# frozen_string_literal: true

module Decidim
  module RestFull
    module ParamsHelper
      extend Grape::API::Helpers

      def populated(default_fields = [:id])
        populated_fields = declared(params, evaluate_given: true)["populate"]
        return default_fields unless populated_fields.any? { |_key, value| value }

        populated_fields.select { |_key, value| value }.keys.push(:id)
      end

      def locales
        selected = declared(params, evaluate_given: true)["locales"]
        return Decidim.available_locales unless selected.any?

        selected
      end

      params :translated do
        optional :locales, type: Array
      end

      params :populated do
        optional :populate, type: Hash do
          System::Organization.available_fields.map do |field_name|
            optional field_name, type: String
          end
        end
      end
    end
  end
end
