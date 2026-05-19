# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class AnswerOptionsController < Decidim::Api::RestFull::ApplicationController
          include ControllerHelpers
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :surveys }
          before_action { ability.authorize! :manage, ::Decidim::Forms::Question }

          def index
            question = find_question!
            options = question.answer_options
            payload = Decidim::Api::RestFull::Forms::AnswerOptionSerializer.new(
              options
            ).serializable_hash.merge(meta: locale_meta)
            render_json_with_conditional_get(
              payload,
              fingerprint: collection_fingerprint_for(options, extra: question.id)
            )
          end

          def create
            enqueue_rest_full_api_job!("forms/answer_options#create")
          end

          def create_sync
            option = Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).create_answer_option!
            end
            render json: Decidim::RestFull::Forms::ResponseBuilder.answer_option(option).merge(meta: locale_meta),
                   status: :created
          end

          def update
            enqueue_rest_full_api_job!("forms/answer_options#update")
          end

          def update_sync
            option = Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).update_answer_option!
            end
            render json: Decidim::RestFull::Forms::ResponseBuilder.answer_option(option).merge(meta: locale_meta)
          end

          def destroy
            enqueue_rest_full_api_job!("forms/answer_options#destroy")
          end

          def destroy_sync
            Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).destroy_answer_option!
            end
            head :no_content
          end

          private

          def find_question!
            qid = filter_hash["question_id"] || params[:question_id]
            raise Decidim::RestFull::Core::ApiException::BadRequest, "filter[question_id] required" if qid.blank?

            question = Decidim::Forms::Question.find(qid)
            questionnaire_scope.find!(question.decidim_questionnaire_id)
            question
          end
        end
      end
    end
  end
end
