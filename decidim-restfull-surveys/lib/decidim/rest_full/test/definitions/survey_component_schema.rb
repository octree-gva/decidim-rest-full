# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :surveys, schema_name: :survey_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:survey_component, :generic_component) do |survey_component|
  survey_component[:title] = "Survey component"
  survey_component[:properties][:type] = { type: :string, enum: ["survey_component"] }
  survey_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["surveys"] }
  survey_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:survey_component)
