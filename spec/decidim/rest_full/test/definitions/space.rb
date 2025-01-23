# frozen_string_literal: true

module Api
  module Definitions
    SPACE_TYPE = {
      type: :string,
      enum: Decidim.participatory_space_registry.manifests.map(&:name)
    }.freeze
    SPACE = {
      type: :object,
      title: "Space",
      properties: {
        id: { type: :string, description: "Space Id" },
        type: { type: :string, enum: ["space"] },
        attributes: {
          title: "Space Attributes",
          type: :object,
          properties: {
            title: {
              "$ref" => "#/components/schemas/translated_prop",
              title: "Title translations",
              description: "Space title"
            },
            subtitle: {
              "$ref" => "#/components/schemas/translated_prop",
              title: "Subtitle translations",
              description: "Space subtitle"
            },
            short_description: {
              "$ref" => "#/components/schemas/translated_prop",
              title: "Short Description translations",
              description: "Space short_description"
            },
            description: {
              "$ref" => "#/components/schemas/translated_prop",
              title: "Description translations",
              description: "Space description"
            },
            manifest_name: { "$ref" => "#/components/schemas/space_manifest" },
            participatory_space_type: { type: :string, example: "Decidim::Assembly" },
            visibility: { type: :string, enum: %w(public transparent private), description: "Space visibility" },
            created_at: { "$ref" => "#/components/schemas/creation_date" },
            updated_at: { "$ref" => "#/components/schemas/edition_date" }
          },
          required: [:title, :manifest_name, :visibility, :created_at, :updated_at],
          additionalProperties: false
        },
        relationships: {
          type: :object,
          title: "Space relationships",
          properties: {
            components: {
              type: :object,
              title: "Attached Components",
              properties: {
                data: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :string },
                      type: {
                        "$ref" => "#/components/schemas/component_type"
                      }
                    },
                    additionalProperties: false,
                    required: [:id, :type]
                  }
                },
                meta: {
                  title: "Attached Components Meta",
                  type: :object,
                  properties: {
                    count: { type: :integer, description: "Total count for components association" }
                  },
                  additionalProperties: false,
                  required: [:count]
                },
                links: {
                  type: :object,
                  title: "Attached Components Links",
                  properties: {
                    self: Api::Definitions.link("Space Detail"),
                    related: Api::Definitions.link("Component List")
                  },
                  additionalProperties: false,
                  required: [:self]
                }
              },
              required: [:data, :meta, :links],
              additionalProperties: false
            }
          },
          required: [:components],
          additionalProperties: false
        },
        links: {
          type: :object,
          title: "Space Links",
          properties: {
            self: Api::Definitions.link("Space Detail"),
            related: Api::Definitions.link("Organization Detail")
          },
          required: [:self, :related],
          additionalProperties: false
        }
      },
      required: [:id, :type, :attributes, :links, :relationships]
    }.freeze
  end
end
