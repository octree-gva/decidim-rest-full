# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:translated_prop) do
  {
    type: :object,
    title: "Translated data",
    description: "Hash with translated data, key=locale value=translation",
    properties: Decidim.available_locales.to_h { |locale| [locale.to_s, { type: :string, description: "Translation in #{locale}" }] },
    additionalProperties: false
  }.freeze
end
