# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:questionnaire) do
  {
    type: :object,
    title: "Questionnaire",
    description: "Decidim::Forms::Questionnaire with JSON Schema and JSON Forms UI for answer submission.",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["questionnaires"] },
      attributes: {
        type: :object,
        properties: {
          title: { type: :string, nullable: true, description: "Localized title for the active locale" },
          description: { type: :string, nullable: true, description: "Localized description for the active locale" },
          schema: { type: :object, description: "JSON Schema (structural only)" },
          ui: { type: :object, description: "JSON Forms UI schema" },
          updated_at: { type: :string, format: :"date-time", nullable: true }
        },
        additionalProperties: true
      },
      meta: {
        type: :object,
        properties: {
          locale: { type: :string },
          requested_locale: { type: :string },
          fallback_from: { type: :string, nullable: true },
          submission: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:forms_submission_policy_meta) }
        },
        additionalProperties: true
      },
      links: {
        type: :object,
        properties: {
          self: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) },
          submit: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) },
          submit_sync: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) },
          questions: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) }
        },
        additionalProperties: {
          "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link)
        }
      }
    },
    required: [:id, :type]
  }
end
