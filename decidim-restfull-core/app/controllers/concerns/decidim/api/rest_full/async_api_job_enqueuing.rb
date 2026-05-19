# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      # Enqueues ApiJob with minimal queue args (job uuid only).
      module AsyncApiJobEnqueuing
        extend ActiveSupport::Concern

        include JobResponseLinking

        private

        def enqueue_rest_full_api_job!(command_key)
          token = doorkeeper_token
          raise Decidim::RestFull::Core::ApiException::Unauthorized, "The access token is invalid" unless token&.accessible?

          job = Decidim::RestFull::ApiJob.compat_create!(
            decidim_organization_id: current_organization.id,
            doorkeeper_access_token_id: token.id,
            oauth_application_id: token.application_id,
            resource_owner_id: token.resource_owner_id,
            command_key:,
            status: "pending",
            payload: rest_full_api_job_payload
          )
          Decidim::RestFull::ExecuteApiJobJob.perform_later(job.id)

          render json: {
            job_id: job.id,
            status: job.status,
            data: nil,
            return_value: nil,
            poll_url: rest_full_job_poll_url(job.id),
            links: rest_full_job_links(job.id)
          }, status: :accepted
        end

        def rest_full_api_job_payload
          path = request.path_parameters.stringify_keys.except("controller", "action", "format")
          extras = params.permit(
            :id, :proposal_id, :object_path, :space_manifest, :space_id, :component_id,
            :manifest_name, :organization_id
          ).to_h.stringify_keys
          data_params = if params.has_key?(:data)
                          params[:data].respond_to?(:permit!) ? params[:data].permit!.to_h : params[:data].to_unsafe_h
                        else
                          {}
                        end
          filter_params = if params[:filter].present?
                            fp = params[:filter]
                            fp.respond_to?(:permit!) ? fp.permit!.to_h : fp.to_unsafe_h
                          else
                            {}
                          end
          {
            "path" => path.merge(extras),
            "data" => data_params,
            "filter" => filter_params
          }.compact
        end

        def api_execution_context
          @api_execution_context ||= Decidim::RestFull::ApiExecutionContext.from_controller(self)
        end
      end
    end
  end
end
