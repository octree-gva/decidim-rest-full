# frozen_string_literal: true

module Api
  module Definitions
    INTROSPECT_DATA = {
      type: :object,
      title: "Introspection Response",
      properties: {
        sub: {
          type: :integer,
          description: "Access token id"
        },
        resource: {
          type: :object,
          properties: {
            id: {
              type: :string,
              description: "resource id"
            },
            type: {
              type: :string,
              enum: ["user"],
              description: "resource type"
            },
            attributes: {
              type: :objet,
              properties: {
                email: {
                  type: :string,
                  description: "Email"
                },
                updated_at: {
                  type: :string,
                  description: "Last update date"
                },
                created_at: {
                  type: :string,
                  description: "Creation date"
                },
                personal_url: {
                  type: :string,
                  description: "Personal url (social link, website, etc.)"
                },
                locale: {
                  type: :string,
                  description: "Current prefered locale",
                  enum: Decidim.available_locales
                }
              },
              required: [:email, :created_at, :updated_at]
            }
          },
          required: [:id, :type]
        }
      },
      required: [:sub]
    }.freeze
  end
end
