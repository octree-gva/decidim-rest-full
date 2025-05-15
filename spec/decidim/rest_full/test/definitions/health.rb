# frozen_string_literal: true

module Api
  module Definitions
    HEALTH_RESPONSE = {
      type: :object,
      properties: {
        message: { type: :string }
      }
    }.freeze
  end
end
