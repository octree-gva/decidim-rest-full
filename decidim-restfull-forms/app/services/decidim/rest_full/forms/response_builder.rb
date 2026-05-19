# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      # Thin facade over JSON:API serializers (keeps controllers terse).
      module ResponseBuilder
        module_function

        def questionnaire_show(questionnaire, projection:, locale_meta:, host:)
          Decidim::Api::RestFull::Forms::QuestionnaireSerializer.new(
            questionnaire,
            params: serializer_params(host:, locale_meta:, locale: locale_meta[:locale], projection:)
          ).serializable_hash
        end

        def questionnaire_index(questionnaires, locale_meta:, host:)
          Decidim::Api::RestFull::Forms::QuestionnaireSerializer.new(
            questionnaires,
            params: serializer_params(host:, locale_meta:, locale: locale_meta[:locale])
          ).serializable_hash
        end

        def questionnaire_response(bundle, locale_meta:, host:)
          Decidim::Api::RestFull::Forms::QuestionnaireResponseSerializer.new(
            bundle,
            params: serializer_params(host:, locale_meta:, locale: locale_meta[:locale])
          ).serializable_hash
        end

        def submission_request(job, host:, result_id: nil)
          Decidim::Api::RestFull::Forms::SubmissionRequestSerializer.new(
            job,
            params: serializer_params(host:, result_id:)
          ).serializable_hash
        end

        def question(question)
          Decidim::Api::RestFull::Forms::QuestionSerializer.new(question).serializable_hash
        end

        def questions(questions, locale_meta:, host:)
          Decidim::Api::RestFull::Forms::QuestionSerializer.new(
            questions,
            params: serializer_params(host:, locale_meta:, locale: locale_meta[:locale])
          ).serializable_hash.merge(meta: locale_meta)
        end

        def answer_option(option)
          Decidim::Api::RestFull::Forms::AnswerOptionSerializer.new(option).serializable_hash
        end

        def answer_index(answers, locale_meta:)
          Decidim::Api::RestFull::Forms::AnswerSerializer.new(answers).serializable_hash.merge(meta: locale_meta)
        end

        def serializer_params(host:, locale_meta: nil, locale: nil, projection: nil, result_id: nil)
          {
            host:,
            locale_meta:,
            locale: locale || locale_meta&.dig(:locale),
            projection:,
            result_id:
          }.compact
        end
      end
    end
  end
end
