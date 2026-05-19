# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:questionnaire_update_body) do
  {
    type: :object,
    title: "Questionnaire metadata update payload",
    required: [:data],
    properties: {
      data: {
        type: :object,
        required: [:type, :id, :attributes],
        properties: {
          type: { type: :string, enum: ["questionnaires"] },
          id: { type: :string },
          attributes: {
            type: :object,
            properties: {
              title: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) },
              description: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) },
              tos: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) }
            },
            additionalProperties: false
          }
        },
        additionalProperties: false
      }
    },
    additionalProperties: false
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:questionnaire_answers_create_body) do
  {
    type: :object,
    title: "Questionnaire answers submission payload",
    properties: {
      meta: {
        type: :object,
        properties: {
          locale: { type: :string },
          anonymous: { type: :boolean },
          client_ip: { type: :string }
        },
        additionalProperties: true
      },
      data: {
        type: :object,
        required: [:type, :attributes, :relationships],
        properties: {
          type: { type: :string, enum: ["questionnaire_response"] },
          attributes: {
            type: :object,
            properties: {
              answers: {
                type: :object,
                additionalProperties: true,
                description: "Map of question id (string) to answer value"
              }
            },
            required: [:answers]
          },
          relationships: {
            type: :object,
            properties: {
              questionnaire: {
                type: :object,
                properties: {
                  data: {
                    type: :object,
                    properties: {
                      type: { type: :string, enum: ["questionnaires"] },
                      id: { type: :string }
                    },
                    required: [:type, :id]
                  }
                },
                required: [:data]
              }
            },
            required: [:questionnaire]
          }
        }
      }
    },
    required: [:data],
    additionalProperties: false
  }.freeze
end
