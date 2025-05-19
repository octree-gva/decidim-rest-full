# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:component_type) do
  {
    type: :string,
    enum: Decidim.component_registry.manifests.map { |manifest| "#{manifest.name.to_s.singularize}_component" }.reject { |manifest_name| manifest_name == "dummy_component" }
  }
end
