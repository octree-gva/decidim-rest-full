# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class ApplicationSerializer < Decidim::Api::RestFull::Core::ApplicationSerializer
          def self.translate_field(field, locale)
            return nil unless field.is_a?(Hash)

            loc = locale.to_s.tr("-", "_").to_sym
            field[loc] || field[locale] || field.values.compact.first
          end

          def self.api_prefix(host)
            "https://#{host}/api"
          end
        end
      end
    end
  end
end
