# frozen_string_literal: true

module Decidim
  module RestFull
    module Entities
      class TranslatedEntity < Grape::Entity
        Decidim.available_locales.map do |locale|
          expose locale.to_s, documentation: { type: "String", desc: "#{locale.upcase} Translation" }
        end
      end
    end
  end
end
