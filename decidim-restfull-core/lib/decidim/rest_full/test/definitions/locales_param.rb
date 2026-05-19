# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:locale) do
  {
    title: "Current locale",
    description: "A single locale code configured for this Decidim instance.",
    type: :string,
    enum: Decidim.available_locales
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:locales) do
  {
    type: :array,
    title: "Available locales",
    description: "List of locale codes the organization exposes.",
    items: { "$ref": Decidim::RestFull::Core::DefinitionRegistry.reference(:locale) }
  }.freeze
end
