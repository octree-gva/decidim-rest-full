# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :meetings, schema_name: :meeting_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:meeting_component, :generic_component) do |meeting_component|
  meeting_component[:title] = "Meeting component"
  meeting_component[:properties][:type] = { type: :string, enum: ["meeting_component"] }
  meeting_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["meetings"] }
  meeting_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:meeting_component)
