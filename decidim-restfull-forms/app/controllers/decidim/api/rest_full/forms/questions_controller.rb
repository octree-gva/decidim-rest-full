# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class QuestionsController < Decidim::Api::RestFull::ApplicationController
          include ControllerHelpers
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :surveys }
          before_action { ability.authorize! :manage, ::Decidim::Forms::Question }

          def index
            questionnaire = questionnaire_for_filter
            questions = questionnaire.questions.order(:position)
            payload = Decidim::RestFull::Forms::ResponseBuilder.questions(
              questions,
              locale_meta:,
              host: current_organization.host
            )
            render_json_with_conditional_get(
              payload,
              fingerprint: collection_fingerprint_for(questions, extra: questionnaire.id)
            )
          end

          def show
            question = find_question!
            render_json_with_conditional_get(
              Decidim::RestFull::Forms::ResponseBuilder.question(question).merge(meta: locale_meta),
              fingerprint: resource_fingerprint_for(question)
            )
          end

          def create
            enqueue_rest_full_api_job!("forms/questions#create")
          end

          def create_sync
            question = Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).create_question!
            end
            render json: Decidim::RestFull::Forms::ResponseBuilder.question(question).merge(meta: locale_meta),
                   status: :created
          end

          def update
            enqueue_rest_full_api_job!("forms/questions#update")
          end

          def update_sync
            question = Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).update_question!
            end
            render json: Decidim::RestFull::Forms::ResponseBuilder.question(question).merge(meta: locale_meta)
          end

          def destroy
            enqueue_rest_full_api_job!("forms/questions#destroy")
          end

          def destroy_sync
            Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).destroy_question!
            end
            head :no_content
          end

          private

          def questionnaire_for_filter
            qid = filter_hash["questionnaire_id"] || params[:questionnaire_id]
            raise Decidim::RestFull::Core::ApiException::BadRequest, "filter[questionnaire_id] required" if qid.blank?

            questionnaire_scope.find!(qid)
          end

          def find_question!
            Decidim::Forms::Question.find(params.require(:id)).tap do |q|
              questionnaire_scope.find!(q.decidim_questionnaire_id)
            end
          end
        end
      end
    end
  end
end
