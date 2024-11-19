# frozen_string_literal: true

# app/serializers/decidim/rest_full/meta_serializer.rb
module Decidim
  module Api
    module RestFull
      class MetaSerializer
        include JSONAPI::Serializer

        attributes :populated, :locales
      end
    end
  end
end
