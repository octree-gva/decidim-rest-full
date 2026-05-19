# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:component_relationship_identifier) do
  {
    type: :object,
    title: "Component relationship identifier",
    description: "JSON:API relationship pointer to a component.",
    properties: {
      id: { type: :string, description: "Component Id" },
      type: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:component_type) }
    },
    required: [:id, :type],
    additionalProperties: false
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:resource_relationship_identifier) do
  {
    type: :object,
    title: "Resource relationship identifier",
    description: "JSON:API relationship pointer to a component resource (proposal, meeting, etc.).",
    properties: {
      id: { type: :string, description: "Resource Id" },
      type: { type: :string, description: "Resource type (e.g. proposals, meetings)" }
    },
    required: [:id, :type],
    additionalProperties: false
  }.freeze
end
