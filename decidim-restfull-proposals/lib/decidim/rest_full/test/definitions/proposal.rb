# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:proposal) do
  {
    type: :object,
    title: "Proposal",
    properties: {
      id: { type: :string, description: "Proposal Id" },
      type: { type: :string, enum: ["proposal"] },
      attributes: {
        type: :object,
        title: "Proposal Attributes",
        properties: {
          title: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
            :description => "Proposal title"
          },
          body: {
            "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
            :description => "Proposal content"
          },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
        },
        required: [:created_at, :updated_at, :title, :body],
        additionalProperties: false
      },
      meta: {
        type: :object,
        title: "Proposal Metadata",
        properties: {
          published: { type: :boolean, description: "Whether the proposal is published" },
          scope: { type: :integer, description: "Scope Id" },
          voted: {
            type: :object,
            title: "Current User Proposal Vote Metadata",
            properties: {
              weight: { type: :integer, description: "Vote weight" }
            },
            required: [:weight],
            additionalProperties: false,
            nullable: true
          }
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
        title: "Proposal Links",
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
        title: "Proposal Relationships",
        properties: {
          state: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("proposal_state", title: "Proposal State Relationship") do |state_schema|
            state_schema[:properties][:meta] = {
              type: :object,
              title: "Proposal State Relationship Metadata",
              properties: {
                token: { type: :string, description: "Proposal State token" }
              },
              required: [:token]
            }

            state_schema[:required].push(:meta)
            state_schema
          end,
          space: Decidim::RestFull::Core::DefinitionRegistry.belongs_to_relation({
                                                                                   "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:space_type)
                                                                                 }, title: "Linked Space"),
          component: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("proposal_component", title: "Linked Proposal Component"),
          author: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("user", "user_group", title: "Proposal's Author"),
          coauthors: Decidim::RestFull::Core::DefinitionRegistry.has_many("user", "user_group", title: "Proposal's Coauthors")
        },
        required: [:component, :space],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :meta, :links]
  }.freeze
end
