# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:introspect_data) do
  {
    type: :object,
    title: "Introspection Response",
    properties: {
      sub: {
        type: :integer,
        description: "Access token id"
      },
      active: {
        type: :boolean,
        description: "If the token can be used"
      },
      aud: {
        type: :string,
        description: "Where this token can be used (organization host)"
      },
      resource: {
        type: :object,
        title: "Resource details",
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
            type: :object,
            title: "Resource Attributes",
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
    required: [:sub, :active, :aud, :exp]
  }.freeze
end
