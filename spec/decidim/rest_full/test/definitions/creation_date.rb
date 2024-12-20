# frozen_string_literal: true

module Api
  module Definitions
    CREATION_DATE = {
      title: "Creation date",
      description: "Creation date, in ISO8601 format.",
      type: :string,
      format: :date_time,
      example: "2024-11-12T12:34:56Z"
    }.freeze
  end
end
