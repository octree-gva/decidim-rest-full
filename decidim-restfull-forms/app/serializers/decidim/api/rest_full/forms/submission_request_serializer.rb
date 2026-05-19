# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class SubmissionRequestSerializer < ApplicationSerializer
          set_type :submission_request

          set_id(&:id)

          attribute :status, &:status

          meta do |job, _params|
            { status: job.status }
          end

          link :self do |job, params|
            {
              href: "#{api_prefix(params[:host])}/submission_requests/#{job.id}",
              rel: "self",
              meta: { action_method: "GET" }
            }
          end

          link :result, if: proc { |job, params| job.status == "completed" && params[:result_id].present? } do |_, params|
            {
              href: "#{api_prefix(params[:host])}/questionnaire_responses/#{params[:result_id]}",
              rel: "result",
              meta: { action_method: "GET" }
            }
          end
        end
      end
    end
  end
end
