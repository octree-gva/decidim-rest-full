# frozen_string_literal: true

module Api
  module Definitions
    COMPONENT = {
      type: :object,
      title: "Component",
      properties: {
        id: { type: :string, example: "1", description: "Component Id" },
        type: { type: :string, enum: ["component"], example: "component" },
        attributes: {
          type: :object,
          properties: {
            title: {
              type: :object,
              additionalProperties: { type: :string },
              example: { en: "Assembly Name", fr: "Nom de l'Assemblée" },
              description: "Component title"
            },
            global_annoucement: {
              type: :object,
              additionalProperties: { type: :string },
              example: { en: "Welcome! You can create", fr: "Bienvenue! Vous pouvez" },
              description: "Component title"
            },
            manifest_name: { type: :string, enum: Decidim.component_registry.manifests.map(&:name) }
          },
          required: [:title, :manifest_name]
        }
      },
      required: [:id, :type]
    }.freeze
  end
end
