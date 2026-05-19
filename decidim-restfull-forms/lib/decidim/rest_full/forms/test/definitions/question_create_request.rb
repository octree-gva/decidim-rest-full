# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      module Definitions
        module QuestionCreateRequest
          BASE_ATTRS = {
            position: { type: :integer, description: "Order within the questionnaire" },
            mandatory: { type: :boolean },
            body: {
              type: :object,
              additionalProperties: { type: :string },
              description: "Translated question label"
            },
            description: {
              type: :object,
              additionalProperties: { type: :string },
              nullable: true
            }
          }.freeze

          QUESTION_CREATE_BODY = {
            type: :object,
            required: [:data],
            properties: {
              data: {
                type: :object,
                required: %w(type attributes relationships),
                properties: {
                  type: { type: :string, enum: ["questions"] },
                  attributes: {
                    oneOf: [
                      {
                        type: :object,
                        required: %w(position mandatory question_type body),
                        properties: BASE_ATTRS.merge(
                          question_type: { type: :string, enum: %w(single_option multiple_option sorting matrix_single matrix_multiple) },
                          max_choices: { type: :integer, nullable: true }
                        ),
                        additionalProperties: false
                      },
                      {
                        type: :object,
                        required: %w(position mandatory question_type body),
                        properties: BASE_ATTRS.merge(
                          question_type: { type: :string, enum: ["long_answer"] },
                          max_characters: { type: :integer, nullable: true }
                        ),
                        additionalProperties: false
                      },
                      {
                        type: :object,
                        required: %w(position mandatory question_type body),
                        properties: BASE_ATTRS.merge(
                          question_type: { type: :string, enum: %w(short_answer files) }
                        ),
                        additionalProperties: false
                      }
                    ]
                  },
                  relationships: {
                    type: :object,
                    required: ["questionnaire"],
                    properties: {
                      questionnaire: {
                        type: :object,
                        required: ["data"],
                        properties: {
                          data: {
                            type: :object,
                            required: %w(type id),
                            properties: {
                              type: { type: :string, enum: ["questionnaires"] },
                              id: { type: :string }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }.freeze
        end
      end
    end
  end
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:question_create_body) do
  Decidim::RestFull::Forms::Definitions::QuestionCreateRequest::QUESTION_CREATE_BODY
end
