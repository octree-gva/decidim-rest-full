# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class SubmissionRequestsController < Decidim::Api::RestFull::ApplicationController
          include ControllerHelpers

          before_action { doorkeeper_authorize! :surveys }

          def show
            job = Decidim::RestFull::ApiJob.find_by(
              id: params.require(:id),
              decidim_organization_id: current_organization.id,
              command_key: "forms/answers#create"
            )
            raise Decidim::RestFull::Core::ApiException::NotFound, "Submission request not found" unless job

            r = job.result.is_a?(Hash) ? job.result.stringify_keys : {}
            rv = r["return_value"] || r["data"] || {}
            rv = rv.stringify_keys if rv.is_a?(Hash)
            result_id = rv["questionnaire_response_id"]
            payload = Decidim::RestFull::Forms::ResponseBuilder.submission_request(
              job,
              host: current_organization.host,
              result_id:
            )
            render_json_with_conditional_get(
              payload,
              fingerprint: resource_fingerprint_for(job),
              headers: job.status == "pending" ? { "Retry-After" => "2" } : {}
            )
          end
        end
      end
    end
  end
end
