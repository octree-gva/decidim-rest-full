# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      # Absolute URLs and +links+ for async API jobs (hypermedia controls, RMM level 3).
      module JobResponseLinking
        extend ActiveSupport::Concern

        private

        def rest_full_job_poll_url(job_id)
          v = Decidim::RestFull.major_minor_version
          "#{request.protocol}#{current_organization.host}/api/rest_full/v#{v}/jobs/#{job_id}"
        end

        def rest_full_job_links(job_id)
          href = rest_full_job_poll_url(job_id)
          {
            self: {
              href:,
              title: "API job status",
              rel: "resource",
              meta: { action_method: "GET" }
            }
          }
        end
      end
    end
  end
end
