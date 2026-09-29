# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Jobs
        class JobsController < Decidim::Api::RestFull::ApplicationController
          include JobResponseLinking

          # Job UUID acts as capability reference; omit Bearer on GET show.
          JOB_ID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

          before_action :require_accessible_token!, only: [:index, :destroy]

          def index
            jobs = base_scope.order(created_at: :desc, id: :desc)
            jobs = apply_job_filters(jobs)
            records, meta = paginate_collection(jobs)
            payload = { data: records.map { |j| serialize_job_summary(j) }, meta: }
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(jobs))
          end

          def show
            requested_id = params.require(:id).to_s
            raise Decidim::RestFull::Core::ApiException::NotFound, "Job not found" unless JOB_ID_PATTERN.match?(requested_id)

            job = Decidim::RestFull::ApiJob
                  .for_organization(current_organization.id)
                  .find_by(id: requested_id)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Job not found" unless job

            render_json_with_conditional_get(serialize_job(job), fingerprint: resource_fingerprint_for(job))
          end

          def destroy
            job = find_owned_job!
            job.destroy!
            head :no_content
          end

          private

          def base_scope
            Decidim::RestFull::ApiJob
              .for_organization(current_organization.id)
              .for_oauth_context(doorkeeper_token.application_id, doorkeeper_token.resource_owner_id)
          end

          def find_owned_job!
            requested_id = params.require(:id).to_s
            raise Decidim::RestFull::Core::ApiException::NotFound, "Job not found" unless JOB_ID_PATTERN.match?(requested_id)

            job = base_scope.find_by(id: requested_id)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Job not found" unless job

            job
          end

          def apply_job_filters(jobs)
            filter = params[:filter] || params["filter"]
            return jobs if filter.blank?

            filter = filter.to_unsafe_h if filter.respond_to?(:to_unsafe_h)
            filter = filter.stringify_keys

            if (command_key = filter["command_key"].presence)
              jobs = jobs.where(command_key:)
            end
            if (status = filter["status"].presence) && Decidim::RestFull::ApiJob::STATUSES.include?(status.to_s)
              jobs = jobs.where(status:)
            end
            jobs
          end

          def require_accessible_token!
            raise Decidim::RestFull::Core::ApiException::Unauthorized, "The access token is invalid" unless doorkeeper_token&.accessible?
          end

          def serialize_job_summary(job)
            {
              id: job.id,
              status: job.status,
              command_key: job.command_key,
              created_at: job.created_at,
              updated_at: job.updated_at,
              links: rest_full_job_links(job.id)
            }
          end

          def serialize_job(job)
            r = job.result.is_a?(Hash) ? job.result.stringify_keys : {}
            {
              id: job.id,
              status: job.status,
              command_key: job.command_key,
              created_at: job.created_at,
              updated_at: job.updated_at,
              error_class: job.error_class,
              error_message: job.error_message,
              data: r["data"],
              return_value: r["return_value"] || r["data"],
              links: rest_full_job_links(job.id)
            }
          end
        end
      end
    end
  end
end
