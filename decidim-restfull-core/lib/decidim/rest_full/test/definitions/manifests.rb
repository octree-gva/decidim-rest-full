# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:space_manifest) do
  {
    title: "Space Manifest",
    description: "Participatory space type key (Decidim manifest name).",
    type: :string,
    enum: Decidim.participatory_space_registry.manifests.map(&:name)
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:component_manifest) do
  {
    title: "Component Manifest",
    description: "Component type key (Decidim manifest name).",
    type: :string,
    enum: Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:resource_manifest) do
  {
    title: "Resource Type",
    description: "Singular resource type string derived from active component manifests.",
    type: :string,
    enum: Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }.map { |manifest_name| manifest_name.to_s.singularize.to_s }
  }.freeze
end
