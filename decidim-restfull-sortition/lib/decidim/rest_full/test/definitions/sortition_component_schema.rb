# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :sortitions, schema_name: :sortition_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:sortition_component, :generic_component) do |sortition_component|
  sortition_component[:title] = "Sortitions component"
  sortition_component[:properties][:type] = { type: :string, enum: ["sortition_component"] }
  sortition_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["sortitions"] }
  sortition_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:sortition_component)
