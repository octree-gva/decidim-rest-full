# frozen_string_literal: true

module Api
  module Definitions
    ERROR = {
      type: :object,
      title: "Api Error",
      properties: {
        error_code: { type: :integer, example: 400, description: "Error code, starting with HTTP Code" },
        message: { type: :string, example: "Bad Request", description: "Error message" },
        detail: { type: :string, description: "Error detail, mostly validation error", example: "Title is required" }
      },
      additionalProperties: false,
      required: [:error_code, :message]
    }.freeze
  end
end
