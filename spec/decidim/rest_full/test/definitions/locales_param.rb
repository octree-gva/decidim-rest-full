# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:locale) do
  {
    title: "Current locale",
    type: :string,
    enum: Decidim.available_locales
  }.freeze
end

Decidim::RestFull::DefinitionRegistry.register_object(:locales) do
  {
    type: :array,
    title: "Available locales",
    items: { "$ref": Decidim::RestFull::DefinitionRegistry.reference(:locale) }
  }.freeze
end
