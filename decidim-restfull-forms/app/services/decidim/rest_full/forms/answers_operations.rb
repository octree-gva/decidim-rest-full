# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      class ValidationError < StandardError
        attr_reader :payload

        def initialize(payload)
          @payload = payload
          super("validation failed")
        end
      end

      # Maps REST answer payloads to Decidim::Forms::AnswerQuestionnaire.
      class AnswersOperations
        def initialize(ctx, params)
          @ctx = ctx
          @params = params
          @organization = ctx.organization
          @payload = extract_payload
        end

        def create!
          questionnaire = load_questionnaire!
          form = build_questionnaire_form(questionnaire)
          raise ValidationError, ErrorPayloadBuilder.from_form(form, locale_meta:) if form.invalid?

          result = nil
          Decidim::Forms::AnswerQuestionnaire.call(form, questionnaire) do
            on(:ok) { result = bundle_after_submit(questionnaire, form) }
            on(:invalid) do
              raise ValidationError, ErrorPayloadBuilder.from_form(form, locale_meta:)
            end
          end
          result
        end

        private

        attr_reader :ctx, :params, :organization, :payload

        def extract_payload
          data = params["data"] || params[:data] || {}
          data = data.to_unsafe_h if data.respond_to?(:to_unsafe_h)
          meta = params["meta"] || params[:meta] || {}
          meta = meta.to_unsafe_h if meta.respond_to?(:to_unsafe_h)
          relationships = data["relationships"] || data[:relationships] || {}
          { data:, meta:, relationships: }
        end

        def load_questionnaire!
          qrel = payload.dig(:relationships, "questionnaire") || payload.dig(:relationships, :questionnaire)
          qdata = qrel&.dig("data") || qrel&.dig(:data)
          qid = qdata&.dig("id") || qdata&.dig(:id)
          raise Decidim::RestFull::Core::ApiException::BadRequest, "relationships.questionnaire required" if qid.blank?

          visibility = ctx.respond_to?(:visibility) ? ctx.visibility : nil
          scope = QuestionnaireScope.new(organization:, visibility:)
          scope.find!(qid)
        end

        def build_questionnaire_form(questionnaire)
          form = Decidim::Forms::QuestionnaireForm.from_model(questionnaire)
          answers_hash = payload.dig(:data, "attributes", "answers") ||
                         payload.dig(:data, :attributes, :answers) || {}
          form.responses = questionnaire.questions.map do |question|
            answer_form = Decidim::Forms::AnswerForm.from_model(
              Decidim::Forms::Answer.new(question:)
            )
            qid = question.id.to_s
            apply_answer!(answer_form, question, answers_hash[qid]) if answers_hash.has_key?(qid)
            answer_form
          end
          form.tos_agreement = true
          form.with_context(form_context(questionnaire))
          form
        end

        def apply_answer!(answer_form, question, value)
          case question.question_type
          when "short_answer", "long_answer"
            answer_form.body = value.to_s
          when "single_option"
            answer_form.choices = [build_choice(value, question)]
          when "multiple_option", "sorting"
            ids = Array(value)
            answer_form.choices = ids.map { |id| build_choice(id, question) }
          when "matrix_single", "matrix_multiple"
            answer_form.choices = value.to_h.map do |row_id, opt_id|
              build_matrix_choice(row_id, opt_id, question)
            end
          end
        end

        def build_choice(option_id, question)
          Decidim::Forms::AnswerChoiceForm.new(
            body: "1",
            answer_option_id: option_id.to_i,
            question:
          )
        end

        def build_matrix_choice(row_id, option_id, question)
          Decidim::Forms::AnswerChoiceForm.new(
            body: "1",
            answer_option_id: option_id.to_i,
            matrix_row_id: row_id.to_i,
            question:
          )
        end

        def form_context(questionnaire)
          respondent = resolve_respondent
          session_token = session_token_for(questionnaire, respondent)
          ip = payload.dig(:meta, "client_ip") || payload.dig(:meta, :client_ip)
          OpenStruct.new(
            current_user: respondent,
            session_token:,
            ip_hash: ip.present? ? tokenize_ip(questionnaire, ip) : nil,
            responses: nil
          )
        end

        def resolve_respondent
          anonymous = payload.dig(:meta, "anonymous") == true || payload.dig(:meta, :anonymous) == true
          return nil if anonymous

          user_rel = payload.dig(:data, "relationships", "user") || payload.dig(:data, :relationships, :user)
          user_data = user_rel&.dig("data") || user_rel&.dig(:data)
          if user_data.present?
            uid = user_data["id"] || user_data[:id]
            return Decidim::User.find_by(id: uid, organization:)
          end

          ctx.current_user
        end

        def session_token_for(questionnaire, user)
          if user
            tokenize(questionnaire, user.id)
          else
            tokenize(questionnaire, SecureRandom.hex(16))
          end
        end

        def tokenize(questionnaire, id)
          Decidim::Tokenizer.new(salt: questionnaire.salt || questionnaire.id, length: 10).int_digest(id).to_s
        end

        def tokenize_ip(questionnaire, ip)
          Decidim::Tokenizer.new(salt: questionnaire.salt || questionnaire.id, length: 10).int_digest(ip).to_s
        end

        def bundle_after_submit(questionnaire, form)
          user = form.current_user
          session_token = form.context.session_token
          anchor = Decidim::Forms::Answer.where(
            decidim_questionnaire_id: questionnaire.id,
            session_token:
          ).order(:id).first
          anchor ||= Decidim::Forms::Answer.where(
            decidim_questionnaire_id: questionnaire.id,
            decidim_user_id: user&.id
          ).order(:id).last
          { questionnaire_response_id: anchor&.id }
        end

        def locale_meta
          LocaleResolver.new(
            organization:,
            user: ctx.current_user,
            params:,
            accept_language: ctx.respond_to?(:request_headers) ? ctx.request_headers["HTTP_ACCEPT_LANGUAGE"] : nil
          ).meta_hash
        end
      end
    end
  end
end
