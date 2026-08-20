# frozen_string_literal: true

# Decidim 0.32 renamed Forms Answer* → Response*. Keep RestFull on historical
# "answer" vocabulary via aliases (models load after Decidim::Forms is required).
# On 0.29, association includes must use :answer_options (aliases do not help AR).
module Decidim
  module RestFull
    module Forms
      module Decidim032Compat
        # API keeps short_answer/long_answer; Decidim 0.32 stores short_response/long_response.
        QUESTION_TYPE_API_TO_DECIDIM = {
          "short_answer" => "short_response",
          "long_answer" => "long_response"
        }.freeze
        QUESTION_TYPE_DECIDIM_TO_API = QUESTION_TYPE_API_TO_DECIDIM.invert.freeze

        module_function

        def response_vocabulary?
          defined?(::Decidim::Forms::Response)
        end

        def question_options_association
          response_vocabulary? ? :response_options : :answer_options
        end

        def api_question_type(decidim_type)
          return decidim_type.to_s unless response_vocabulary?

          QUESTION_TYPE_DECIDIM_TO_API.fetch(decidim_type.to_s, decidim_type.to_s)
        end

        def decidim_question_type(api_type)
          return api_type.to_s unless response_vocabulary?

          QUESTION_TYPE_API_TO_DECIDIM.fetch(api_type.to_s, api_type.to_s)
        end

        def apply!
          return unless response_vocabulary?
          return if ::Decidim::Forms.const_defined?(:Answer, false)

          ::Decidim::Forms.const_set(:Answer, ::Decidim::Forms::Response)
          ::Decidim::Forms.const_set(:AnswerOption, ::Decidim::Forms::ResponseOption)
          ::Decidim::Forms.const_set(:AnswerChoice, ::Decidim::Forms::ResponseChoice)
          ::Decidim::Forms.const_set(:AnswerForm, ::Decidim::Forms::ResponseForm)
          ::Decidim::Forms.const_set(:AnswerChoiceForm, ::Decidim::Forms::ResponseChoiceForm)
          ::Decidim::Forms.const_set(:AnswerQuestionnaire, ::Decidim::Forms::ResponseQuestionnaire)

          ::Decidim::Forms::Question.class_eval do
            alias_method :answer_options, :response_options unless method_defined?(:answer_options)
            alias_method :answers, :responses unless method_defined?(:answers)
          end

          ::Decidim::Forms::Questionnaire.class_eval do
            alias_method :answers, :responses unless method_defined?(:answers)
          end
        end
      end
    end
  end
end
