# frozen_string_literal: true

module Api
  module Definitions
    BLOG = {
      type: :object,
      title: "Blog Post",
      properties: {
        id: { type: :string, example: "1", description: "Blog Post Id" },
        type: { type: :string, enum: ["blog"] },
        attributes: {
          type: :object,
          properties: {
            title: {
              "$ref" => "#/components/schemas/translated_prop",
              example: { en: "My Blog post", fr: "Mon post de blog" },
              description: "Blog post title"
            },
            body: {
              "$ref" => "#/components/schemas/translated_prop",
              example: { en: "Blog post content", fr: "Ceci est un contenu" },
              description: "Blog post body content"
            },
            created_at: { type: :string, description: "Creation date of the component" },
            updated_at: { type: :string, description: "Last update date of the component" }
          },
          required: [:created_at, :updated_at, :title, :body],
          additionalProperties: false
        },
        meta: {
          type: :object,
          title: "Blog Post Metadata",
          properties: {
            published: { type: :boolean, description: "Published blog post?" },
            scope: { type: :integer, description: "Scope Id" }
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
          required: [:published]
        },
        links: {
          type: :object,
          title: "Blog Post Links",
          properties: {
            self: { type: :string, description: "API URL to the blog post" }
          },
          additionalProperties: false,
          required: [:self]
        },
        relationships: {
          type: :object,
          title: "Blog Post Relationships",
          properties: {
            space: {
              type: :object,
              properties: {
                data: {
                  type: :object,
                  properties: {
                    id: { type: :string, description: "Space Id" },
                    type: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }
                  },
                  required: [:id, :type]
                }
              },
              required: [:data]
            },
            component: {
              type: :object,
              properties: {
                data: {
                  type: :object,
                  properties: {
                    id: { type: :string, description: "Component Id" },
                    type: { type: :string, enum: Decidim.component_registry.manifests.map { |manifest| "#{manifest.name.to_s.singularize}_component" }.reject { |manifest_name| manifest_name == "dummy_component" }, description: "Component type" }
                  },
                  required: [:id, :type]
                }
              },
              required: [:data]
            }
          },
          required: [],
          additionalProperties: false
        }
      },
      required: [:id, :type, :attributes, :meta, :links]
    }.freeze
  end
end
