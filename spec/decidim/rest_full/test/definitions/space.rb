# frozen_string_literal: true

module Api
  module Definitions
    SPACE = {
      type: :object,
      title: "Space"
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
            visibility: { type: :string, enum: %w(public transparent private), description: "Space visibility" },
            components: {
              type: :array,
              items: {
                type: :object,
                title: "Component Summary",
                properties: {
                  id: { type: :integer, example: 2, description: "Component Id" },
                  manifest_name: { type: :string, enum: Decidim.component_registry.manifests.map(&:name) }
                },
                required: [:id, :manifest_name]
              }
            }
          },
          required: [:title, :manifest_name, :visibility, :components]
        },
      },
      required: [:id, :type]
    }.freeze
  end
end
