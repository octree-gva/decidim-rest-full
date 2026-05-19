# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class AnswersController < Decidim::Api::RestFull::ApplicationController
          include ControllerHelpers
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :surveys }
          before_action { ability.authorize! :submit, ::Decidim::Forms::Questionnaire }

          def index
            ability.authorize! :read, ::Decidim::Forms::Answer
            relation = answers_corpus
            relation = apply_answer_filters(relation)
            page = paginate_relation(relation.order(created_at: :desc))
            payload = Decidim::RestFull::Forms::ResponseBuilder.answer_index(page, locale_meta:)
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(page))
          end

          def create
            enqueue_forms_answer_job!
          end

          def create_sync
            result = Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AnswersOperations.new(api_context, request.params).create!
            end
            bundle = Decidim::RestFull::Forms::SubmissionBundle.find!(
              result[:questionnaire_response_id],
              organization: current_organization,
              visibility: participatory_space_visibility
            )
            json = Decidim::RestFull::Forms::ResponseBuilder.questionnaire_response(
              bundle,
              locale_meta:,
              host: current_organization.host
            )
            render json:, status: :created, location: json.dig(:data, :links, :self, :href)
          rescue Decidim::RestFull::Forms::ValidationError => e
            render json: e.payload, status: :unprocessable_entity
          end

          private

          def enqueue_forms_answer_job!
            token = doorkeeper_token
            raise Decidim::RestFull::Core::ApiException::Unauthorized, "The access token is invalid" unless token&.accessible?

            job = Decidim::RestFull::ApiJob.compat_create!(
              decidim_organization_id: current_organization.id,
              doorkeeper_access_token_id: token.id,
              oauth_application_id: token.application_id,
              resource_owner_id: token.resource_owner_id,
              command_key: "forms/answers#create",
              status: "pending",
              payload: rest_full_api_job_payload
            )
            Decidim::RestFull::ExecuteApiJobJob.perform_later(job.id)

            body = Decidim::RestFull::Forms::ResponseBuilder.submission_request(job, host: current_organization.host)
            render json: body,
                   status: :accepted,
                   location: body.dig(:data, :links, :self, :href),
                   headers: { "Retry-After" => "2" }
          end

          def answers_corpus
            qids = questionnaire_scope.base_relation.pluck(:id)
            Decidim::Forms::Answer.where(decidim_questionnaire_id: qids)
          end

          def apply_answer_filters(relation)
            relation = relation.where(decidim_questionnaire_id: filter_hash["questionnaire_id"]) if filter_hash["questionnaire_id"].present?
            relation
          end
        end
      end
    end
  end
end
