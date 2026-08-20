# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:meeting) do
  {
    type: :object,
    title: "Meeting",
    properties: {
      id: { type: :string, description: "Meeting Id" },
      type: { type: :string, enum: ["meeting"] },
      attributes: {
        type: :object,
        title: "Meeting Attributes",
        properties: {
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) },
          extended_data: {
            type: :object,
            additionalProperties: true,
            description: "Present when the client has meetings.extended_data.read"
          }
        },
        required: [:created_at, :updated_at],
        additionalProperties: true
      },
      links: {
        type: :object,
        title: "Meeting Links",
        properties: {
          self: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          collection: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          related: Decidim::RestFull::Core::DefinitionRegistry.resource_link
        },
        additionalProperties: false,
        required: [:self, :collection, :related]
      },
      relationships: {
        type: :object,
        title: "Meeting Relationships",
        properties: {
          space: Decidim::RestFull::Core::DefinitionRegistry.belongs_to_relation(
            { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:space_type) },
            title: "Linked Space"
          ),
          component: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("meeting_component", title: "Linked Meeting Component")
        },
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :links]
  }.freeze
end
