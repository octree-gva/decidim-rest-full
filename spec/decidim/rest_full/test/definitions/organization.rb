# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_resource(:organization) do
  {
    type: :object,
    title: "Organization",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["organization"] },
      attributes: {
        type: :object,
        properties: {
          name: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
            additionalProperties: { type: :string }
          },
          host: { type: :string },
          available_locales: Decidim::RestFull::DefinitionRegistry.schema_for(:locales),
          default_locale: { type: :string, description: "defaut locale for the organization" },
          secondary_hosts: { type: :array, items: { type: :string, description: "Additional host, will redirect (301) to `host`" } },
          created_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:edition_date) }
        },
        additionalProperties: false,
        required: [:created_at, :updated_at, :host, :name, :available_locales, :default_locale]
      },
      meta: {
        type: :object,
        properties: {
          locales: Decidim::RestFull::DefinitionRegistry.schema_for(:locales)
        },
        required: [:locales],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :meta]
  }.freeze
end
