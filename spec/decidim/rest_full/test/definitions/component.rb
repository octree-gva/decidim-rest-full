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
              "$ref" => "#/components/schemas/translated_prop",
              example: { en: "Component Name", fr: "Nom du composant" },
              description: "Component name"
            },
            global_announcement: {
              "$ref" => "#/components/schemas/translated_prop",
              example: { en: "Welcome! You can create", fr: "Bienvenue! Vous pouvez" },
              description: "Component annoucement (intro)"
            },
            manifest_name: {
              type: :string,
              enum: Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy },
              description: "Manifest name of the component"
            },
            participatory_space_type: {
              type: :string,
              example: "Decidim::Assembly",
              description: "Associate space class name. Part of the polymorphic association (participatory_space_type,participatory_space_id)"
            },
            participatory_space_id: { type: :string, description: "Associate space id. Part of the polymorphic association (participatory_space_type,participatory_space_id)" },
            created_at: { type: :string, description: "Creation date of the component" },
            updated_at: { type: :string, description: "Last update date of the component" }
          },
          required: [:created_at, :updated_at, :name, :manifest_name, :participatory_space_type, :participatory_space_id],
          additionalProperties: false
        },
        meta: {
          type: :object,
          title: "Component Metadata",
          properties: {
            published: { type: :boolean, description: "Published component?" },
            scopes_enabled: { type: :boolean, description: "Component handle scopes?" }
          },
          additionalProperties: {
            oneOf: [
              {
                type: :boolean
              },
              {
                type: :integer
              },
              {
                type: :string
              },
              {
                "$ref" => "#/components/schemas/translated_prop"
              }
            ]
          },
          required: [:published, :scopes_enabled]
        },
        links: {
          type: :object,
          title: "Component Links",
          properties: {
            self: { type: :string, description: "API URL to the component" },
            related: { type: :string, description: "Component details API URL" }
          },
          additionalProperties: false,
          required: [:self, :related]
        },
        relationships: {
          type: :object,
          title: "Component Relationships",
          properties: {
            resources: {
              type: :object,
              title: "Component Resources Descriptor",
              properties: {
                data: {
                  type: :array,
                  title: "Component Resource Sample (max 50items)",
                  items: {
                    type: :object,
                    title: "Component Resource",
                    properties: {
                      id: { type: :string, description: "Resource ID" },
                      type: { type: :string, description: "Resource Type" }
                    },
                    required: [:id, :type]
                  }
                },
                meta: {
                  type: :object,
                  title: "Component Resource Descriptor Meta",
                  properties: {
                    count: { type: :integer, description: "Total count of resources" }
                  },
                  required: [:count]
                }
              },
              required: [:data, :meta]
            }
          },
          required: [:resources],
          additionalProperties: false
        }
      },
      required: [:id, :type, :attributes, :meta, :links]
    }.freeze
  end
end
