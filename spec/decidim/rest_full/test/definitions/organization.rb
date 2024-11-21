# frozen_string_literal: true

# spec/support/api_schemas/organization_schema.rb
module Api
  module Definitions
    ORGANIZATION = {
      type: :object,
      title: "Organization",
      properties: {
        id: { type: :string, example: "1" },
        type: { type: :string, enum: ["organization"], example: "organization" },
        attributes: {
          type: :object,
          properties: {
            name: {
              type: :object,
              additionalProperties: { type: :string },
              example: { en: "Organization Name", fr: "Nom de l'organisation" }
            },
            host: { type: :string, example: "example.org" },
            secondaryHosts: { type: :array, items: { type: :string }, example: ["secondary.example.org"] },
            created_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" },
            updated_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" }
          },
          required: [:created_at, :updated_at]
        },
        meta: {
          type: :object,
          properties: {
            locales: { type: :array, items: { type: :string }, example: %w(en fr) }
          },
          required: [:locales]
        }
      },
      required: [:id, :type, :attributes, :meta]
    }.freeze
  end
end
