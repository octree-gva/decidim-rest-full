# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      # Projects Decidim::Forms::Questionnaire to JSON Schema + JSON Forms UI.
      class QuestionnaireJsonFormsBuilder
        def initialize(questionnaire, locale:, organization:, host:)
          @questionnaire = questionnaire
          @locale = locale
          @organization = organization
          @host = host
        end

        def build
          {
            schema: build_schema,
            ui: build_ui,
            meta: build_submission_meta
          }
        end

        private

        attr_reader :questionnaire, :locale, :organization, :host

        def build_schema
          properties = {}
          questionnaire.questions.each do |question|
            next if question.separator? || question.title_and_description?

            key = question.id.to_s
            properties[key] = schema_for_question(question)
          end
          { type: "object", properties:, required: [] }
        end

        def build_ui
          elements = questionnaire.questions.filter_map do |question|
            ui_element_for_question(question)
          end
          { type: "VerticalLayout", elements: }
        end

        def build_submission_meta
          {
            allows_anonymous: allows_anonymous?,
            requires_participant_ip: requires_participant_ip?
          }
        end

        def allows_anonymous?
          host = questionnaire.questionnaire_for
          return true if host.is_a?(Decidim::Surveys::Survey)

          false
        end

        def requires_participant_ip?
          allows_anonymous?
        end

        def schema_for_question(question)
          case question.question_type
          when "single_option", "multiple_option", "sorting"
            { type: "string", title: translate(question.body), enum: question.answer_options.map { |o| o.id.to_s } }
          when "matrix_single", "matrix_multiple"
            row_props = question.matrix_rows.index_with { |_row| { type: "string" } }
            { type: "object", title: translate(question.body), properties: row_props.transform_keys { |r| r.id.to_s } }
          else
            { type: "string", title: translate(question.body) }
          end
        end

        def ui_element_for_question(question)
          return { type: "Group", label: translate(question.body), elements: [] } if question.separator?

          control = {
            type: "Control",
            scope: "#/properties/#{question.id}",
            label: translate(question.body)
          }
          control[:options] = control_options(question) if needs_options?(question)
          rule = display_rule(question)
          control[:rule] = rule if rule
          control
        end

        def needs_options?(question)
          question.question_type.in?(%w(single_option multiple_option sorting matrix_single matrix_multiple))
        end

        def control_options(question)
          opts = {
            choices: question.answer_options.map { |o| choice_hash(o) }
          }
          opts[:matrix] = { rowId: question.matrix_rows.first&.id&.to_s } if question.matrix?
          opts
        end

        def choice_hash(option)
          translations = (option.body || {}).stringify_keys
          { id: option.id.to_s, translations: }
        end

        def display_rule(question)
          condition = question.display_conditions.first
          return nil unless condition

          cond_qid = condition.condition_question_id
          effect = "SHOW"
          schema_fragment = case condition.condition_type
                            when "equal"
                              { const: condition.decidim_answer_option_id.to_s }
                            else
                              { minLength: 1 }
                            end
          {
            effect:,
            condition: {
              scope: "#/properties/#{cond_qid}",
              schema: schema_fragment
            }
          }
        end

        def translate(field)
          return "" unless field.is_a?(Hash)

          loc = locale.tr("-", "_").to_sym
          field[loc] || field[locale] || field[organization.default_locale.to_sym] || field.values.compact.first.to_s
        end
      end
    end
  end
end
