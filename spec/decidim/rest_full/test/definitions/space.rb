# frozen_string_literal: true

module Api
  module Definitions
    SPACE = {
      type: :object,
      title: "Space",
      properties: {
        id: { type: :string, example: "1", description: "Space Id" },
        type: { type: :string, enum: ["space"], example: "space" },
        attributes: {
          title: "Space Attributes",
          type: :object,
          properties: {
            title: {
              "$ref" => "#/components/schemas/translated_prop",
              title: "Title translations",
              example: { en: "Assembly Name", fr: "Nom de l'Assemblée" },
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
            manifest_name: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name) },
            participatory_space_type: { type: :string, example: "Decidim::Assembly" },
            visibility: { type: :string, enum: %w(public transparent private), description: "Space visibility" },
            created_at: { type: :string, description: "Space creation date" },
            updated_at: { type: :string, description: "Last update of the space" }
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
                        type: :string,
                        enum: Decidim.component_registry.manifests.map { |manifest| "#{manifest.name.to_s.singularize}_component" }.reject { |manifest_name| manifest_name == "dummy_component" }
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
                    related: {
                      type: :string,
                      description: "Complete list"
                    }
                  },
                  additionalProperties: false,
                  required: [:related]
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
            self: {
              type: :string
            }
          },
          required: [:self],
          additionalProperties: false
        }
      },
      required: [:id, :type, :attributes, :links, :relationships]
    }.freeze
  end
end
