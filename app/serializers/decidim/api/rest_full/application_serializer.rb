# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ApplicationSerializer
        def self.translated_field(translated_value, locales)
          translated_value = JSON.parse(translated_value) if translated_value.is_a?(String)
          default_values = locales.index_with { |_l| "" }
          default_values.merge(
            (translated_value || {}).select { |key| locales.include?(key.to_sym) }
          )
        end
      end
    end
  end
end
