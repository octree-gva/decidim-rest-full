# frozen_string_literal: true

module Decidim
  module RestFull
    class ExecuteApiJobJob < Decidim::RestFull::ApplicationJob
      discard_on ActiveRecord::RecordNotFound

      def perform(api_job_id)
        api_job = Decidim::RestFull::ApiJob.lock.find(api_job_id)
        api_job.validate_token_for_job!
        # Intentionally skip validations/callbacks: row is locked; only status flip for worker visibility.
        api_job.update_columns(status: "processing", updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

        org = api_job.organization
        token = api_job.doorkeeper_access_token
        ctx = Decidim::RestFull::ApiExecutionContext.new(organization: org, doorkeeper_token: token)
        params = Decidim::RestFull::ApiJobPayload.params_from_job(api_job)

        result = Decidim::RestFull::SyncRunner.call do
          Decidim::RestFull::ApiJobCommandRunner.run!(ctx, api_job.command_key, params)
        end

        api_job.update!(
          status: "completed",
          result: wrap_result(result),
          error_class: nil,
          error_message: nil
        )
      rescue StandardError => e
        fail_job!(api_job, e)
      end

      def self.wrap_result(value)
        { "data" => value, "return_value" => value }
      end

      private

      def wrap_result(value)
        self.class.wrap_result(value)
      end

      def fail_job!(api_job, error)
        return unless api_job

        api_job.update(
          status: "failed",
          error_class: error.class.name,
          error_message: error.message.to_s.truncate(65_000),
          result: {}
        )
      end
    end
  end
end
