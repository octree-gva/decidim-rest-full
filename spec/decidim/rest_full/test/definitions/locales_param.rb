# frozen_string_literal: true

module Api
  module Definitions
    LOCALES_PARAM = {
      type: :array,
      title: "Locales enumeration",
      items: { type: :string, enum: Decidim.available_locales }
    }.freeze
    LOCALE_PARAM = {
      title: "Locale",
      type: :string,
      enum: Decidim.available_locales
    }.freeze
  end
end
