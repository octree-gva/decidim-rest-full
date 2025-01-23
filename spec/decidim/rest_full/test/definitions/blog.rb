# frozen_string_literal: true

module Api
  module Definitions
    BLOG = {
      type: :object,
      title: "Blog Post",
      properties: {
        id: { type: :string, description: "Blog Post Id" },
        type: { type: :string, enum: ["blog"] },
        attributes: {
          type: :object,
          properties: {
            title: {
              "$ref" => "#/components/schemas/translated_prop",
              description: "Blog post title"
            },
            body: {
              "$ref" => "#/components/schemas/translated_prop",
              description: "Blog post body content"
            },
            created_at: { "$ref" => "#/components/schemas/creation_date" },
            updated_at: { "$ref" => "#/components/schemas/edition_date" }
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
            self: Api::Definitions.link("Blog Post"),
            collection: Api::Definitions.link("Associate blog post list"),
            related: Api::Definitions.link("Related Component"),
            prev: Api::Definitions.link("Prev blog post entry", [nil, {}]),
            next: Api::Definitions.link("Next blog post entry", [nil, {}])
          },
          additionalProperties: false,
          required: [:self, :collection, :related, :prev, :next]
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
                    type: { "$ref" => "#/components/schemas/component_type" }
                  },
                  required: [:id, :type]
                }
              },
              required: [:data]
            }
          },
          required: [:component, :space],
          additionalProperties: false
        }
      },
      required: [:id, :type, :attributes, :meta, :links]
    }.freeze
  end
end
