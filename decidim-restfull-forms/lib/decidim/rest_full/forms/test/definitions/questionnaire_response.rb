# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:questionnaire_response) do
  {
    type: :object,
    title: "Questionnaire response (submission bundle)",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["questionnaire_response"] },
      attributes: {
        type: :object,
        properties: {
          answers: {
            type: :object,
            additionalProperties: true,
            description: "Map of question_id to answer value"
          },
          client_ip: { type: :string, nullable: true, description: "Opaque ip_hash digest" }
        },
        required: [:answers]
      },
      meta: { type: :object, additionalProperties: true },
      links: {
        type: :object,
        properties: {
          self: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) }
        },
        additionalProperties: {
          "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link)
        }
      },
      relationships: {
        type: :object,
        properties: {
          questionnaire: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("questionnaires", title: "Questionnaire")
        }
      }
    },
    required: [:id, :type, :attributes]
  }
end
