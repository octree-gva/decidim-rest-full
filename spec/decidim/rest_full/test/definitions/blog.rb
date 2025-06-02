# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_resource(:blog) do
  {
    type: :object,
    title: "Blog Post",
    properties: {
      id: { type: :string, description: "Blog Post Id" },
      type: { type: :string, enum: ["blog"] },
      attributes: {
        type: :object,
        title: "Blog Post Attributes",
        properties: {
          title: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop)
          },
          body: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop)
          },
          created_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:edition_date) }
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
              "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop)
            }
          ]
        },
        required: [:published]
      },
      links: {
        type: :object,
        title: "Blog Post Links",
        properties: {
          self: Decidim::RestFull::DefinitionRegistry.resource_link,
          collection: Decidim::RestFull::DefinitionRegistry.resource_link,
          related: Decidim::RestFull::DefinitionRegistry.resource_link,
          prev: Decidim::RestFull::DefinitionRegistry.resource_link,
          next: Decidim::RestFull::DefinitionRegistry.resource_link
        },
        additionalProperties: false,
        required: [:self, :collection, :related]
      },
      relationships: {
        type: :object,
        title: "Blog Post Relationships",
        properties: {
          space: Decidim::RestFull::DefinitionRegistry.belongs_to(*Decidim.participatory_space_registry.manifests.map(&:name), title: "Linked Space"),
          component: Decidim::RestFull::DefinitionRegistry.belongs_to("blog_component", title: "Linked Blog Component")
        },
        required: [:component, :space],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :meta, :links]
  }.freeze
end
