# frozen_string_literal: true

# spec/support/api_schemas/organization_schema.rb
module Api
  module Definitions
    ORGANIZATION = {
      type: :object,
      properties: {
        id: { type: :string, example: "1" },
        type: { type: :string, example: "organization" },
        attributes: {
          properties: {
            id: { type: :integer, example: 1 },
            name: {
              type: :object,
              additionalProperties: { type: :string },
              example: { en: "Organization Name", fr: "Nom de l'organisation" }
            },
            host: { type: :string, example: "example.org" },
            secondaryHosts: { type: :array, items: { type: :string }, example: ["secondary.example.org"] },
            meta: {
              type: :object,
              properties: {
                populated: { type: :array, items: { type: :string }, example: %w(id name) },
                locales: { type: :array, items: { type: :string }, example: %w(en fr) }
              }
            },
            created_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" },
            updated_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" }
          },
          required: [:id, :created_at, :updated_at]
        }
      },
      required: [:id]
    }.freeze
  end
end
