# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:blog) do
  {
    type: :object,
    title: "Post",
    properties: {
      id: { type: :string, description: "Post id (Blogs::Post)" },
      type: { type: :string, enum: ["blog"], description: "JSON:API type discriminator for this resource" },
      attributes: {
        type: :object,
        title: "Post attributes",
        properties: {
          title: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop)
          },
          body: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop)
          },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) },
          published_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:publication_date) }
        },
        required: [:created_at, :updated_at, :title, :body],
        additionalProperties: false
      },
      meta: {
        type: :object,
        title: "Post metadata",
        properties: {
          published: { type: :boolean, description: "Whether the post is published" },
          scope: { type: :integer, description: "Scope id (component or participatory space scope)" }
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
              "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop)
            }
          ]
        },
        required: [:published]
      },
      links: {
        type: :object,
        title: "Post links",
        properties: {
          self: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          collection: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          related: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          prev: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          next: Decidim::RestFull::Core::DefinitionRegistry.resource_link
        },
        additionalProperties: false,
        required: [:self, :collection, :related]
      },
      relationships: {
        type: :object,
        title: "Post relationships",
        properties: {
          space: Decidim::RestFull::Core::DefinitionRegistry.belongs_to(*Decidim.participatory_space_registry.manifests.map(&:name), title: "Linked participatory space"),
          component: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("blog_component", title: "Linked blogs component")
        },
        required: [:component, :space],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :meta, :links]
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:blog_post_create_payload) do
  {
    type: :object,
    title: "Blog post create payload",
    required: [:data],
    properties: {
      data: {
        type: :object,
        required: [:component_id, :attributes],
        properties: {
          component_id: { type: :integer, description: "Blogs component id" },
          attributes: {
            type: :object,
            required: [:title, :body],
            properties: {
              title: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) },
              body: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) },
              published_at: {
                type: :string,
                format: :"date-time",
                nullable: true,
                description: "ISO8601; omit or null for draft"
              }
            },
            additionalProperties: false
          }
        },
        additionalProperties: false
      }
    },
    additionalProperties: false
  }.freeze
end
