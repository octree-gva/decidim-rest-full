# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class QuestionnaireResponsesController < Decidim::Api::RestFull::ApplicationController
          include ControllerHelpers
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :surveys }

          def show
            ability.authorize! :read, ::Decidim::Forms::Answer
            bundle = Decidim::RestFull::Forms::SubmissionBundle.find!(
              params.require(:id),
              organization: current_organization,
              visibility: participatory_space_visibility
            )
            payload = Decidim::RestFull::Forms::ResponseBuilder.questionnaire_response(
              bundle,
              locale_meta:,
              host: current_organization.host
            )
            anchor = Decidim::Forms::Answer.find_by(id: bundle.anchor_id)
            render_json_with_conditional_get(
              payload,
              fingerprint: anchor ? resource_fingerprint_for(anchor) : nil
            )
          end

          def destroy
            enqueue_rest_full_api_job!("forms/questionnaire_responses#destroy")
          end

          def destroy_sync
            ability.authorize! :destroy, ::Decidim::Forms::Answer
            Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Forms::AuthoringOperations.new(api_context, request.params).destroy_questionnaire_response!
            end
            head :no_content
          end

          def update_forbidden
            head :method_not_allowed, allow: "GET, HEAD, DELETE"
          end
        end
      end
    end
  end
end
