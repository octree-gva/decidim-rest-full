# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:draft_proposal) do
  {
    type: :object,
    title: "Draft Proposal",
    properties: {
      id: { type: :string, description: "Draft Proposal Id" },
      type: { type: :string, enum: ["draft_proposal"] },
      attributes: {
        title: "Draft Proposal Attributes",
        type: :object,
        properties: {
          title: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
            :description => "Draft Proposal title"
          },
          body: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
            :description => "Draft Proposal content"
          },
          errors: {
            type: :object,
            title: "Draft Proposal Validation Errors",
            properties: {
              title: {
                type: :array,
                items: { type: :string }
              },
              body: {
                type: :array,
                items: { type: :string }
              }
            },
            required: [:title, :body],
            description: "Draft current errors"
          },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
        },
        required: [:created_at, :updated_at, :title, :body],
        additionalProperties: false
      },
      meta: {
        type: :object,
        title: "Draft Proposition Metadata",
        properties: {
          publishable: { type: :boolean, description: "Draft is published as it is now?" },
          client_id: { type: :string, description: "Attached client_id" },
          scope: { type: :integer, description: "Scope Id" },
          fields: { type: :array, description: "Editable field names", items: { type: :string } }
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
        required: [:publishable, :client_id, :fields]
      },
      links: {
        type: :object,
        title: "Proposal Links",
        properties: {
          self: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          collection: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          related: Decidim::RestFull::Core::DefinitionRegistry.resource_link
        },
        additionalProperties: false,
        required: [:self, :related, :collection]
      },
      relationships: {
        type: :object,
        title: "Draft Proposal Relationships",
        properties: {
          space: Decidim::RestFull::Core::DefinitionRegistry.belongs_to_relation({
                                                                                   "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:space_type)
                                                                                 }, title: "Draft Proposal Related Space"),
          component: Decidim::RestFull::Core::DefinitionRegistry.belongs_to_relation({
                                                                                       "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:component_type)
                                                                                     }, title: "Draft Proposal Related Component"),
          author: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("user", "user_group", title: "Draft Proposal Author"),
          coauthors: Decidim::RestFull::Core::DefinitionRegistry.has_many("user", "user_group", title: "Draft Proposal Coauthors")
        },
        required: [:component, :space],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :meta, :links]
  }.freeze
end
