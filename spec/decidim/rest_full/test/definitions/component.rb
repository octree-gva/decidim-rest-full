# frozen_string_literal: true

module Api
  module Definitions
    COMPONENT = {
      type: :object,
      title: "Component",
      properties: {
        id: { type: :string, example: "1", description: "Component Id" },
        type: { type: :string, enum: Decidim.component_registry.manifests.map { |manifest| "#{manifest.name.to_s.singularize}_component" }.reject { |manifest_name| manifest_name == "dummy_component" } },
        attributes: {
          type: :object,
          properties: {
            name: {
              type: :object,
              additionalProperties: { type: :string },
              example: { en: "Component Name", fr: "Nom du composant" },
              description: "Component name"
            },
            global_announcement: {
              type: :object,
              additionalProperties: { type: :string },
              example: { en: "Welcome! You can create", fr: "Bienvenue! Vous pouvez" },
              description: "Component annoucement (intro)"
            },
            manifest_name: { type: :string, enum: Decidim.component_registry.manifests.map(&:name) },
            participatory_space_type: { type: :string, example: "Decidim::Assembly" },
            participatory_space_id: { type: :string }
          },
          required: [:name, :manifest_name, :participatory_space_type, :participatory_space_id]
        }
      },
      required: [:id, :type]
    }.freeze
  end
end
