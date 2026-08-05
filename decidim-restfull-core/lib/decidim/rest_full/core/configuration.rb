# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class Configuration
        class << self
          def config = self

          def configure
            yield self
          end

          # Core-only defaults. Feature gems merge via +Extension.register+ (+ext.permissions+ / +ext.webhook_event+).
          def default_available_permissions
            always_available_permissions
          end

          private

          def always_available_permissions
            {
              "system" => system_permissions,
              "public" => %w(public.component.read public.space.read),
              "oauth" => %w(
                oauth.magic_link oauth.extended_data.read oauth.extended_data.update
                user.created user.updated
              ),
              "attachments" => %w(attachments.read attachments.write attachments.destroy),
              "webhooks" => %w(webhooks.read webhooks.write webhooks.destroy)
            }
          end

          def system_permissions
            %w(
              oauth.impersonate oauth.login
              system.organizations.read system.organizations.update system.organizations.destroy
              system.organizations.extended_data.read system.organizations.extended_data.update
              system.organizations.created system.organizations.updated system.organizations.deleted
            )
          end
        end

        mattr_accessor :loadbalancer_ips
        mattr_accessor :queue_name
        mattr_accessor :max_async_api_job_payload_bytes
        mattr_accessor :max_extended_data_payload_bytes
        mattr_accessor :docs_url
        mattr_accessor :available_permissions
        mattr_accessor :events_for_proposals
        mattr_accessor :events_for_oauth
        mattr_accessor :events_for_system
        mattr_accessor :events_for_meetings
        mattr_accessor :strict_rest_enhancement_http_cache

        self.loadbalancer_ips = begin
          ips = ENV.fetch("DECIDIM_REST_LOADBALANCER_IPS", "127.0.0.1, ::1").split(",").map(&:strip)
          ips.map { |ip| IPAddr.new(ip) }.map(&:to_s)
        end

        self.queue_name = ENV.fetch("DECIDIM_REST_QUEUE_NAME", "default")

        # Optional cap on async ApiJob JSON payload size (measured as +payload.to_json.bytesize+).
        # +nil+ (default) means no engine-level limit; the row is stored as +jsonb+ and the Active Job
        # only serializes the job id, so queue adapters (Sidekiq, Good Job, etc.) do not impose this cap.
        self.max_async_api_job_payload_bytes = begin
          val = ENV.fetch("DECIDIM_REST_MAX_ASYNC_API_JOB_PAYLOAD_BYTES", nil)
          if val.blank?
            nil
          else
            Integer(val)
          end
        rescue ArgumentError
          nil
        end

        # Cap for sync extended_data writes (JSON bytes of the stored hash). +nil+ = no limit.
        # Falls back to +max_async_api_job_payload_bytes+ when the dedicated env is unset.
        self.max_extended_data_payload_bytes = begin
          val = ENV.fetch("DECIDIM_REST_MAX_EXTENDED_DATA_PAYLOAD_BYTES", nil)
          if val.blank?
            max_async_api_job_payload_bytes
          else
            Integer(val)
          end
        rescue ArgumentError
          max_async_api_job_payload_bytes
        end

        self.docs_url = ENV.fetch("DOCS_URL", "https://octree-gva.github.io/decidim-rest-full")

        self.available_permissions = default_available_permissions

        # Feature gems assign these in their engine initializers (see proposals / meetings).
        self.events_for_proposals = []

        self.events_for_oauth = [
          "user.created",
          "user.updated"
        ]

        self.events_for_system = [
          "system.organizations.created",
          "system.organizations.updated",
          "system.organizations.deleted"
        ]

        self.events_for_meetings = []

        # When true, +rest_enhancement+ with +http_cache_profile+ and relationship/meta but no +cache_time+ raises at boot.
        # When false (default), log a warning in development/test only.
        self.strict_rest_enhancement_http_cache = false
      end
    end
  end
end
