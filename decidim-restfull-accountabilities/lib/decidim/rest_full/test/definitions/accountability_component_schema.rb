# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :accountability, schema_name: :accountability_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:accountability_component, :generic_component) do |accountability_component|
  accountability_component[:title] = "Accountability component"
  accountability_component[:properties][:type] = { type: :string, enum: ["accountability_component"] }
  accountability_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["accountability"] }
  accountability_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:accountability_component)
