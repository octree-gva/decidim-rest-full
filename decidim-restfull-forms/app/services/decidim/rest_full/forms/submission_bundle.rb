# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      # Groups persisted answers into one questionnaire_response bundle.
      class SubmissionBundle
        def self.find!(response_id, organization:, visibility: nil)
          anchor = Decidim::Forms::Answer.find_by(id: response_id)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Submission not found" unless anchor

          scope = QuestionnaireScope.new(organization:, visibility:)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Submission not found" unless scope.organization_for(anchor.questionnaire)&.id == organization.id

          answers = Decidim::Forms::Answer.where(
            decidim_questionnaire_id: anchor.decidim_questionnaire_id,
            decidim_user_id: anchor.decidim_user_id,
            session_token: anchor.session_token
          ).includes(:question, :choices)

          new(anchor_id: anchor.id, answers: answers.to_a, questionnaire: anchor.questionnaire)
        end

        attr_reader :anchor_id, :answers, :questionnaire

        def id
          anchor_id.to_s
        end

        def initialize(anchor_id:, answers:, questionnaire:)
          @anchor_id = anchor_id
          @answers = answers
          @questionnaire = questionnaire
        end

        def answers_map
          answers.each_with_object({}) do |answer, hash|
            next if answer.question.separator? || answer.question.title_and_description?

            hash[answer.decidim_question_id.to_s] = serialize_answer(answer)
          end
        end

        def user
          answers.first&.user
        end

        def ip_hash
          answers.first&.ip_hash
        end

        def created_at
          answers.map(&:created_at).compact.min
        end

        private

        def serialize_answer(answer)
          if answer.choices.any?
            if answer.question.matrix?
              answer.choices.each_with_object({}) do |choice, h|
                row_id = choice.decidim_question_matrix_row_id
                h[row_id.to_s] = choice.decidim_answer_option_id.to_s if row_id
              end
            else
              answer.choices.map { |c| c.decidim_answer_option_id.to_s }
            end
          else
            answer.body
          end
        end
      end
    end
  end
end
