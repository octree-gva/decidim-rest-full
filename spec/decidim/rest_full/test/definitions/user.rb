# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_resource(:user) do
  {
    type: :object,
    title: "User",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["user"] },
      meta: {
        title: "User Metadata",
        type: :object,
        properties: {
          blocked: { type: :boolean, description: "If the user is blocked, and need to be unblocked to signin" },
          locked: { type: :boolean, description: "If the user is locked, and need to click on the mail link to unlock" }

        },
        required: [:blocked, :locked],
        additionalProperties: false
      },
      relationships: {
        type: :object,
        title: "User Relationships",
        properties: {
          roles: {
            type: :object,
            title: "User Roles",
            properties: {
              data: {
                type: :array,
                items: {
                  type: :object,
                  title: "User Role",
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
        title: "User Attributes",
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
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:locale),
            description: "User locale. Fallback to default locale of the organization. Private"
          },
          email: {
            description: "Email of the user. Private",
            type: :string
          },
          extended_data: {
            type: :object,
            title: "User Extended Data",
            description: "Additional data. Private",
            properties: {},
            additionalProperties: true
          },
          created_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:edition_date) }
        },
        additionalProperties: false,
        required: [:created_at, :updated_at, :name, :nickname, :locale, :extended_data]
      }
    },
    required: [:id, :type, :attributes],
    additionalProperties: false
  }.freeze
end
