# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:forms_validation_error_item) do
  {
    type: :object,
    title: "Forms validation error",
    properties: {
      title: { type: :string },
      code: { type: :string },
      pointer: { type: :string, description: "JSON Pointer into the request body" },
      question_id: { type: :string, nullable: true }
    },
    required: [:title, :code],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:forms_validation_error_response) do
  {
    type: :object,
    title: "Forms validation error response",
    properties: {
      meta: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:forms_locale_meta) },
      errors: {
        type: :array,
        items: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:forms_validation_error_item) }
      }
    },
    required: [:errors],
    additionalProperties: false
  }
end
