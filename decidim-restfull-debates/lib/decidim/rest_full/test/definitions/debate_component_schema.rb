# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :debates, schema_name: :debate_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:debate_component, :generic_component) do |debate_component|
  debate_component[:title] = "Debates component"
  debate_component[:properties][:type] = { type: :string, enum: ["debate_component"] }
  debate_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["debates"] }
  debate_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:debate_component)
