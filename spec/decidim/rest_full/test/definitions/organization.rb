# frozen_string_literal: true

# spec/support/api_schemas/organization_schema.rb
module Api
  module Definitions
    ORGANIZATION = {
      type: :object,
      title: "Organization",
      properties: {
        id: { type: :string },
        type: { type: :string, enum: ["organization"] },
        attributes: {
          type: :object,
          properties: {
            name: {
              "$ref" => "#/components/schemas/translated_prop",
              additionalProperties: { type: :string }
            },
            host: { type: :string },
            available_locales: { "$ref" => "#/components/schemas/locales" },
            default_locale: { type: :string, description: "defaut locale for the organization" },
            secondary_hosts: { type: :array, items: { type: :string, description: "Additional host, will redirect (301) to `host`" } },
            created_at: { "$ref" => "#/components/schemas/creation_date" },
            updated_at: { "$ref" => "#/components/schemas/edition_date" }
          },
          additionalProperties: false,
          required: [:created_at, :updated_at, :host, :name, :available_locales, :default_locale]
        },
        meta: {
          type: :object,
          properties: {
            locales: { "$ref" => "#/components/schemas/locales" }
          },
          required: [:locales],
          additionalProperties: false
        }
      },
      required: [:id, :type, :attributes, :meta]
    }.freeze
  end
end
