# frozen_string_literal: true

module Decidim
  module RestFull
    # Durable async API write record: minimal queue args (uuid only); payload and result stored here.
    class ApiJob < ::ApplicationRecord
      self.table_name = "decidim_rest_full_api_jobs"

      STATUSES = %w(pending processing completed failed).freeze

      belongs_to :organization,
                 foreign_key: :decidim_organization_id,
                 class_name: "Decidim::Organization",
                 inverse_of: false

      belongs_to :doorkeeper_access_token,
                 class_name: "Doorkeeper::AccessToken",
                 optional: false

      validates :command_key, presence: true
      validates :status, inclusion: { in: STATUSES }
      validate :rest_full_payload_size, if: -> { payload.present? && rest_full_payload_max_bytes&.positive? }

      # Some databases still enforce +poll_secret+ until +20260516153000_remove_poll_secret_from_decidim_rest_full_api_jobs+
      # runs; generate one automatically when that column exists.
      def self.compat_create!(attributes)
        attrs = attributes.symbolize_keys
        attrs[:poll_secret] ||= SecureRandom.urlsafe_base64(32) if column_names.include?("poll_secret")
        create!(attrs)
      end

      scope :for_token, ->(token_id) { where(doorkeeper_access_token_id: token_id) }
      scope :for_organization, ->(org_id) { where(decidim_organization_id: org_id) }

      # Any access token from the same OAuth application and resource owner (not the same token row).
      scope :for_oauth_context, lambda { |application_id, resource_owner_id|
        rel = where(oauth_application_id: application_id)
        if resource_owner_id.present?
          rel.where(resource_owner_id:)
        else
          rel.where(resource_owner_id: nil)
        end
      }

      def terminal?
        status.in?(%w(completed failed))
      end

      def validate_token_for_job!
        token = doorkeeper_access_token
        raise Decidim::RestFull::Core::ApiException::Unauthorized, "Invalid token" unless token

        app = token.application
        raise Decidim::RestFull::Core::ApiException::Unauthorized, "Invalid application" unless app.is_a?(Decidim::RestFull::Core::ApiClient)
        raise Decidim::RestFull::Core::ApiException::Forbidden, "Organization mismatch" if app.decidim_organization_id != decidim_organization_id

        token
      end

      private

      def rest_full_payload_max_bytes
        Decidim::RestFull.config.max_async_api_job_payload_bytes
      end

      def rest_full_payload_size
        max = rest_full_payload_max_bytes
        return if payload.to_json.bytesize <= max

        errors.add(:payload, "exceeds maximum size of #{max} bytes")
      end
    end
  end
end
