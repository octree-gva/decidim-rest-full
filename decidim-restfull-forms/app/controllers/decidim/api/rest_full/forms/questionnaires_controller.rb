# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class QuestionnairesController < Decidim::Api::RestFull::ApplicationController
          include ControllerHelpers
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :surveys }
          before_action { authorize_read! }

          def index
            relation = questionnaire_scope.filter(questionnaire_scope.base_relation, filter_hash)
            page = paginate_relation(relation.order(updated_at: :desc))
            payload = Decidim::RestFull::Forms::ResponseBuilder.questionnaire_index(
              page,
              locale_meta:,
              host: current_organization.host
            )
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(page))
          end

          def show
            questionnaire = questionnaire_scope.find!(params.require(:id))
            render_json_with_conditional_get(
              questionnaire_show_json(questionnaire),
              fingerprint: resource_fingerprint_for(questionnaire)
            )
          end

          def update
            enqueue_rest_full_api_job!("forms/questionnaires#update")
          end

          def update_sync
            questionnaire = Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).update_questionnaire!
            end
            render_json_with_conditional_get(
              questionnaire_show_json(questionnaire),
              fingerprint: resource_fingerprint_for(questionnaire)
            )
          end

          private

          def authorize_read!
            return ability.authorize! :read, ::Decidim::Forms::Questionnaire if ability.can?(:read, ::Decidim::Forms::Questionnaire)

            ability.authorize! :read, ::Decidim::Surveys::Survey
          end

          def authorize_manage!
            ability.authorize! :manage, ::Decidim::Forms::Question
          end
        end
      end
    end
  end
end
