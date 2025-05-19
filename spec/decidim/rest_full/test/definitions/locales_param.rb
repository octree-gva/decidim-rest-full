# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:locales) do
  {
    type: :array,
    title: "Locales enumeration",
    items: { type: :string, enum: Decidim.available_locales }
  }.freeze
end

Decidim::RestFull::DefinitionRegistry.register_object(:locale) do
  {
    title: "Locale",
    type: :string,
    enum: Decidim.available_locales
  }.freeze
end
