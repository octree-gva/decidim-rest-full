# frozen_string_literal: true

# Polymorphic JSON:API +:component+ (+oneOf+ of manifest-specific schemas + +:other_component+) is
# built by +DefinitionRegistry.finalize_openapi_component_resource_schema!+ after optional engines call
# +register_component_manifest_schema+.
Decidim::RestFull::Core::DefinitionRegistry.register_object(:generic_component) do
  {
    type: :object,
    title: "Component",
    properties: {
      id: { type: :string, description: "Component Id" },
      type: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:component_type) },
      attributes: {
        title: "Component Attributes",
        type: :object,
        properties: {
          name: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
            :description => "Component name"
          },
          global_announcement: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
            :description => "Component announcement (intro)"
          },
          participatory_space_type: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:space_classes)
          },
          participatory_space_id: { type: :string, description: "Associate space id. Part of the polymorphic association (participatory_space_type,participatory_space_id)" },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
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
              "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop)
            }
          ]
        },
        required: [:published, :scopes_enabled]
      },
      links: {
        type: :object,
        title: "Component Links",
        properties: {
          self: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          related: Decidim::RestFull::Core::DefinitionRegistry.resource_link
        },
        additionalProperties: false,
        required: [:self]
      },
      relationships: {
        type: :object,
        title: "Component Relationships",
        properties: {
          resources: Decidim::RestFull::Core::DefinitionRegistry.has_many_relation(
            nil,
            title: "Component Linked Resources",
            item_schema_key: :resource_relationship_identifier
          ) do |component_schema|
                       component_schema[:properties][:meta] = {
                         type: :object,
                         title: "Component Linked Resources Metadata",
                         properties: {
                           count: { type: :integer, description: "Total count of resources" }
                         },
                         required: [:count]
                       }
                       component_schema[:required].push(:meta)
                       component_schema
                     end
        }
      }
    }
  }.freeze
end
