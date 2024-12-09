# frozen_string_literal: true

module Api
  module Definitions
    LOCALES_PARAM = {
      type: :array,
      description: "accepted locales in response",
      items: { type: :string, enum: Decidim.available_locales }
    }.freeze
  end
end
