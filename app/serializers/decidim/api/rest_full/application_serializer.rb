# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ApplicationSerializer
        include ::JSONAPI::Serializer
        def self.translated_field(translated_value, locales)
          translated_value = JSON.parse(translated_value) if translated_value.is_a?(String)
          filter = locales || Decidim.available_locales.map(&:to_sym)
          (translated_value || {}).select { |key| filter.include?(key.to_sym) }
        end
      end
    end
  end
end
