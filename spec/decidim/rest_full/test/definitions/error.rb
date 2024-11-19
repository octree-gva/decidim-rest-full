# frozen_string_literal: true

module Api
  module Definitions
    ERROR = {
      type: :object,
      properties: {
        error_code: { type: :integer, example: 400 },
        message: { type: :string, example: "Bad Request" },
        details: { type: :string, example: "Title is required" }
      },
      required: [:error_code, :message]
    }.freeze
  end
end
