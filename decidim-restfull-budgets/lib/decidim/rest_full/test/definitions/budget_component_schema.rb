# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :budgets, schema_name: :budget_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:budget_component, :generic_component) do |budget_component|
  budget_component[:title] = "Budget component"
  budget_component[:properties][:type] = { type: :string, enum: ["budget_component"] }
  budget_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["budgets"] }
  budget_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:budget_component)
