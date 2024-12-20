# frozen_string_literal: true

module Api
  module Definitions
    ERROR = {
      type: :object,
      title: "Api Error",
      properties: {
        error: { type: :string, description: "Error title, starting with HTTP Code, like 400: bad request" },
        error_description: { type: :string, description: "Error detail, mostly validation error" },
        state: { type: :string, description: "authentification state" }
      },
      additionalProperties: false,
      required: [:error, :error_description]
    }.freeze
  end
end
