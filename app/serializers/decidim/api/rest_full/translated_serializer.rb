# frozen_string_literal: true

# app/serializers/decidim/rest_full/translated_serializer.rb
module Decidim
  module Api
    module RestFull
      class TranslatedSerializer
        include JSONAPI::Serializer

        # Dynamically include translations for each locale
        Decidim.available_locales.each do |locale|
          attribute locale.to_s do |translated_object|
            translated_object[locale.to_s]
          end
        end
      end
    end
  end
end
