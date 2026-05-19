# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :blogs, schema_name: :blog_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:blog_component, :generic_component) do |blog_component|
  blog_component[:title] = "Blogs component"
  blog_component[:properties][:type] = { type: :string, enum: ["blog_component"] }
  blog_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["blogs"] }
  blog_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:blog_component)
