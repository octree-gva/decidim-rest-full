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
              type: :object,
              title: "Title translations",
              additionalProperties: { type: :string },
              example: { en: "Assembly Name", fr: "Nom de l'Assemblée" },
              description: "Space title"
            },
            subtitle: {
              type: :object,
              title: "Subtitle translations",
              additionalProperties: { type: :string },
              description: "Space subtitle"
            },
            short_description: {
              type: :object,
              title: "Short Description translations",
              additionalProperties: { type: :string },
              description: "Space short_description"
            },
            description: {
              type: :object,
              title: "Description translations",
              additionalProperties: { type: :string },
              description: "Space description"
            },
            manifest_name: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name) },
            participatory_space_type: { type: :string, example: "Decidim::Assembly" },
            visibility: { type: :string, enum: %w(public transparent private), description: "Space visibility" }
          },
          required: [:title, :manifest_name, :visibility]
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
                      type: { type: :string, enum: Decidim.component_registry.manifests.map { |manifest| "#{manifest.name.to_s.singularize}_component" }.reject { |manifest_name| manifest_name == "dummy_component" } }
                    },
                    required: [:id, :type]
                  }
                },
                meta: {
                  type: :object,
                  properties: {
                    count: { type: :integer }
                  },
                  required: [:count]
                }
              },
              required: [:data, :meta]
            }
          },
          required: [:components]
        },
        links: {
          type: :object,
          title: "Space Links",
          properties: {
            self: {
              type: :string
            }
          },
          required: [:self]
        }
      },
      required: [:id, :type, :attributes, :links, :relationships]
    }.freeze
  end
end
