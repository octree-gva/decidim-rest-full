# frozen_string_literal: true

# spec/support/api_schemas/organization_schema.rb
module Api
  module Definitions
    USER = {
      type: :object,
      title: "User",
      properties: {
        id: { type: :string, example: "1" },
        type: { type: :string, enum: ["user"], example: "user" },
        attributes: {
          type: :object,
          properties: {
            name: {
              type: :string
            },
            nickname: {
              type: :string
            },
            locale: {
              type: :string,
              enum: Decidim.available_locales
            },
            personal_url: {
              type: :string
            },
            email: {
              type: :string
            },
            about: {
              type: :string
            },
            created_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" },
            updated_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" }
          },
          additionalProperties: false,
          required: [:created_at, :updated_at, :name, :nickname]
        }
      },
      required: [:id, :type, :attributes]
    }.freeze
  end
end
