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
        meta: {
          type: :object,
          properties: {
            blocked: { type: :boolean, description: "If the user is blocked, and need to be unblocked to signin" },
            locked: { type: :boolean, description: "If the user is locked, and need to click on the mail link to unlock" }

          },
          required: [:blocked, :locked],
          additionalProperties: {
            oneOf: [
              { type: :boolean },
              { type: :string }
            ]
          }
        },
        relationships: {
          type: :object,
          properties: {
            roles: {
              type: :object,
              properties: {
                data: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :string },
                      type: { type: :string, enum: ["user_role"] }
                    },
                    required: [:id, :type],
                    additionalProperties: false
                  }
                }
              },
              required: [:data],
              additionalProperties: false
            }
          }
        },
        attributes: {
          type: :object,
          properties: {
            name: {
              description: "User name, use to display the Profile identity. Public",
              type: :string
            },
            nickname: {
              description: "User nickname, unique identifier for the user. Public",
              type: :string
            },
            personal_url: {
              description: "Personal website URL or social link. Public",
              type: :string
            },
            about: {
              description: "Short bio of the user. Public",
              type: :string
            },
            locale: {
              description: "User locale. Fallback to default locale of the organization. Private",
              type: :string,
              enum: Decidim.available_locales
            },
            email: {
              description: "Email of the user. Private",
              type: :string
            },
            created_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" },
            updated_at: { type: :string, format: :date_time, example: "2024-11-12T12:34:56Z" }
          },
          additionalProperties: false,
          required: [:created_at, :updated_at, :name, :nickname, :locale]
        }
      },
      required: [:id, :type, :attributes],
      additionalProperties: false
    }.freeze
  end
end
