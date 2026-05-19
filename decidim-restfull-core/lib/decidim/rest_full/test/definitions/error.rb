# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:error) do
  {
    type: :object,
    title: "API error payload",
    properties: {
      error: { type: :string, description: "Summary label; typically includes HTTP status (e.g. `400: Bad request`)." },
      error_description: { type: :string, description: "Human-readable detail; for many 4xx responses this is the validation or exception message." },
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
