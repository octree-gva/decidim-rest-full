# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:error_detail) do
  {
    type: :object,
    title: "API error detail",
    properties: {
      code: { type: :string, description: "Stable ActiveModel error type (e.g. `blank`, `too_short`, `too_much_caps`)." },
      field: { type: :string, description: "Attribute name when the error targets a request field (e.g. `title`, `body`)." },
      description: { type: :string, description: "Human-readable full message for this single validation error." }
    },
    additionalProperties: false,
    required: [:code]
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:error) do
  {
    type: :object,
    title: "API error payload",
    properties: {
      error: { type: :string, description: "Summary label; typically includes HTTP status (e.g. `400: Bad request`)." },
      error_description: { type: :string, description: "Human-readable detail; for many 4xx responses this is the validation or exception message." },
      error_details: {
        type: :array,
        description: "Machine-readable validation errors when present (e.g. draft proposal update/publish). One entry per ActiveModel error.",
        items: { "$ref": Decidim::RestFull::Core::DefinitionRegistry.reference(:error_detail) }
      },
      state: { type: :string, description: "Optional OAuth layer hint present on some token errors (e.g. `unauthorized`)." }
    },
    additionalProperties: false,
    required: [:error, :error_description]
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:error_response) do
  {
    "$ref": Decidim::RestFull::Core::DefinitionRegistry.reference(:error)
  }.freeze
end
