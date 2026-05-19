# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:question) do
  {
    type: :object,
    title: "Question",
    description: "Authoring row for a single Decidim::Forms::Question (admin CRUD).",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["questions"] },
      attributes: {
        type: :object,
        properties: {
          position: { type: :integer },
          mandatory: { type: :boolean },
          question_type: { type: :string },
          body: { type: :object, additionalProperties: true, description: "Translated fields (may include machine_translations)" },
          description: { type: :object, additionalProperties: true, nullable: true },
          max_choices: { type: :integer, nullable: true },
          max_characters: { type: :integer, nullable: true }
        }
      },
      relationships: {
        type: :object,
        properties: {
          questionnaire: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("questionnaires", title: "Questionnaire")
        }
      }
    },
    required: [:id, :type]
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:answer_option) do
  {
    type: :object,
    title: "Answer option",
    description: "Selectable option for single/multiple choice questions.",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["answer_options"] },
      attributes: {
        type: :object,
        properties: {
          body: { type: :object, additionalProperties: { type: :string } }
        }
      },
      relationships: {
        type: :object,
        properties: {
          question: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("question", title: "Question")
        }
      }
    },
    required: [:id, :type]
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:answer) do
  {
    type: :object,
    title: "Answer row",
    description: "Stored Decidim::Forms::Answer (corpus listing, not the submission bundle).",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["answers"] },
      attributes: {
        type: :object,
        properties: {
          body: { type: :string, nullable: true },
          question_id: { type: :string }
        }
      },
      relationships: {
        type: :object,
        properties: {
          questionnaire: Decidim::RestFull::Core::DefinitionRegistry.belongs_to("questionnaires", title: "Questionnaire")
        }
      }
    },
    required: [:id, :type]
  }
end
