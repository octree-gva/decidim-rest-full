# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      # Sync/async commands for questionnaire authoring (questions, options, metadata).
      class AuthoringOperations
        def initialize(ctx, params)
          @ctx = ctx
          @params = params
          @organization = ctx.organization
        end

        def update_questionnaire!
          questionnaire = scope.find!(resource_id)
          attrs = data_attributes.permit(:tos, title: {}, description: {}).to_h
          questionnaire.update!(attrs) if attrs.present?
          questionnaire.reload
        end

        def create_question!
          questionnaire = scope.find!(questionnaire_id_from_relationship!)
          questionnaire.questions.create!(question_attributes)
        end

        def update_question!
          question = find_question!
          question.update!(question_attributes)
          question
        end

        def destroy_question!
          find_question!.destroy!
          true
        end

        def create_answer_option!
          question = find_question_by_filter!
          body = data_attributes.permit(body: {}).to_h["body"] || {}
          question.answer_options.create!(body:)
        end

        def update_answer_option!
          option = find_answer_option!
          body = data_attributes.permit(body: {}).to_h["body"] || {}
          option.update!(body:)
          option
        end

        def destroy_answer_option!
          find_answer_option!.destroy!
          true
        end

        def destroy_questionnaire_response!
          bundle = SubmissionBundle.find!(
            resource_id,
            organization: @organization,
            visibility:
          )
          bundle.answers.each(&:destroy!)
          true
        end

        private

        attr_reader :ctx, :params, :organization

        def scope
          @scope ||= QuestionnaireScope.new(organization:, visibility:)
        end

        def visibility
          ctx.respond_to?(:visibility) ? ctx.visibility : nil
        end

        def resource_id
          path_id = params.dig("path", "id") || params.dig(:path, :id)
          (path_id || params[:id] || params["id"]).to_s
        end

        def data_attributes
          data = params["data"] || params[:data] || {}
          data = data.to_unsafe_h if data.respond_to?(:to_unsafe_h)
          attrs = data["attributes"] || data[:attributes] || {}
          attrs = attrs.to_unsafe_h if attrs.respond_to?(:to_unsafe_h)
          ActionController::Parameters.new(attrs)
        end

        def question_attributes
          data_attributes.permit(
            :position, :mandatory, :question_type, :max_choices, :max_characters, body: {}, description: {}
          ).to_h
        end

        def questionnaire_id_from_relationship!
          qid = questionnaire_id_from_relationship
          raise Decidim::RestFull::Core::ApiException::BadRequest, "relationships.questionnaire required" if qid.blank?

          qid
        end

        def questionnaire_id_from_relationship
          questionnaire_relationship_data&.dig("id") || questionnaire_relationship_data&.dig(:id)
        end

        def questionnaire_relationship_data
          rel = request_data_payload.dig("relationships", "questionnaire") ||
                request_data_payload.dig(:relationships, :questionnaire)
          rel&.dig("data") || rel&.dig(:data)
        end

        def request_data_payload
          data = params["data"] || params[:data] || {}
          data.respond_to?(:to_unsafe_h) ? data.to_unsafe_h : data
        end

        def find_question!
          Decidim::Forms::Question.find(resource_id).tap do |q|
            scope.find!(q.decidim_questionnaire_id)
          end
        end

        def find_question_by_filter!
          qid = filter_hash["question_id"] || params.dig("path", "question_id") || params[:question_id]
          raise Decidim::RestFull::Core::ApiException::BadRequest, "filter[question_id] required" if qid.blank?

          question = Decidim::Forms::Question.find(qid)
          scope.find!(question.decidim_questionnaire_id)
          question
        end

        def find_answer_option!
          Decidim::Forms::AnswerOption.find(resource_id).tap do |o|
            question = Decidim::Forms::Question.find(o.decidim_question_id)
            scope.find!(question.decidim_questionnaire_id)
          end
        end

        def filter_hash
          fp = params["filter"] || params[:filter] || params.dig("path", "filter")
          return {} if fp.blank?

          fp.respond_to?(:to_unsafe_h) ? fp.to_unsafe_h.stringify_keys : fp.to_h.stringify_keys
        rescue StandardError
          {}
        end
      end
    end
  end
end
