# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:locale) do
  {
    title: "Current locale",
    type: :string,
    enum: Decidim.available_locales
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:locales) do
  {
    type: :array,
    title: "Available locales",
    items: { "$ref": Decidim::RestFull::Core::DefinitionRegistry.reference(:locale) }
  }.freeze
end
