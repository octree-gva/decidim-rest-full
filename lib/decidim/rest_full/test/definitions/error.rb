# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:error) do
  {
    type: :object,
    title: "Api Error Payload",
    properties: {
      error: { type: :string, description: "Error title, starting with HTTP Code, like 400: bad request" },
      error_description: { type: :string, description: "Error detail, mostly validation error" },
      state: { type: :string, description: "authentification state" }
    },
    additionalProperties: false,
    required: [:error, :error_description]
  }.freeze
end

Decidim::RestFull::DefinitionRegistry.register_object(:error_response) do
  {
    "$ref": Decidim::RestFull::DefinitionRegistry.reference(:error)
  }.freeze
end
