# frozen_string_literal: true

module Decidim
  module RestFull
    # Rebuilds ActionController::Parameters from JSON persisted on ApiJob.
    module ApiJobPayload
      module_function

      def params_from_job(api_job)
        h = api_job.payload.with_indifferent_access
        path = (h[:path] || {}).stringify_keys
        data = h[:data].is_a?(Hash) ? h[:data] : {}
        merged = path.merge("data" => data)
        merged["filter"] = h[:filter] if h[:filter].is_a?(Hash)
        ActionController::Parameters.new(merged)
      end
    end
  end
end
