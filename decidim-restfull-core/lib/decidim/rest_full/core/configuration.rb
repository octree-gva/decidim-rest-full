# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class Configuration
        include ActiveSupport::Configurable

        config_accessor :loadbalancer_ips do
          ips = ENV.fetch("DECIDIM_REST_LOADBALANCER_IPS", "127.0.0.1, ::1").split(",").map(&:strip)
          ips.map { |ip| IPAddr.new(ip) }.map(&:to_s)
        end

        config_accessor :queue_name do
          ENV.fetch("DECIDIM_REST_QUEUE_NAME", "default")
        end

        # Optional cap on async ApiJob JSON payload size (measured as +payload.to_json.bytesize+).
        # +nil+ (default) means no engine-level limit; the row is stored as +jsonb+ and the Active Job
        # only serializes the job id, so queue adapters (Sidekiq, Good Job, etc.) do not impose this cap.
        config_accessor :max_async_api_job_payload_bytes do
          val = ENV.fetch("DECIDIM_REST_MAX_ASYNC_API_JOB_PAYLOAD_BYTES", nil)
          next nil if val.blank?

          Integer(val)
        rescue ArgumentError
          nil
        end

        config_accessor :docs_url do
          ENV.fetch("DOCS_URL", "https://octree-gva.github.io/decidim-rest-full")
        end

        # When false, Proposals engine does not mount proposal API routes or apply proposal overrides.
        config_accessor :enable_proposals_api do
          true
        end

        # When false, Blogs engine does not mount blog API routes.
        config_accessor :enable_blogs_api do
          true
        end

        config_accessor :enable_debates_api do
          true
        end

        config_accessor :enable_surveys_api do
          true
        end

        config_accessor :enable_forms_api do
          true
        end

        config_accessor :enable_meetings_api do
          true
        end

        config_accessor :enable_attachments_api do
          true
        end

        config_accessor :enable_budgets_api do
          true
        end

        config_accessor :enable_accountabilities_api do
          true
        end

        config_accessor :enable_sortition_api do
          true
        end

        config_accessor :available_permissions do
          {
            "blogs" => [
              "blogs.read",
              "blogs.write",
              "blogs.destroy"
            ],
            "system" => [
              "oauth.impersonate",
              "oauth.login",
              "system.organizations.read",
              "system.organizations.update",
              "system.organizations.destroy",
              "system.organizations.extended_data.read",
              "system.organizations.extended_data.update",
              *config.events_for_system
            ],
            "public" => [
              "public.component.read",
              "public.space.read"
            ],
            "proposals" => [
              "proposals.read", "proposals.draft", "proposals.vote",
              *config.events_for_proposals
            ],
            "debates" => [
              "debates.read"
            ],
            "budgets" => [
              "budgets.read"
            ],
            "surveys" => [
              "surveys.read",
              "surveys.questionnaires.read",
              "surveys.questions.manage",
              "surveys.answers.read",
              "surveys.answers.submit",
              "surveys.answers.destroy"
            ],
            "accountability" => [
              "accountability.read"
            ],
            "sortitions" => [
              "sortitions.read"
            ],
            "meetings" => [
              "meetings.read",
              *config.events_for_meetings
            ],
            "oauth" => [
              "oauth.magic_link",
              "oauth.extended_data.read",
              "oauth.extended_data.update",
              *config.events_for_oauth
            ],
            "attachments" => [
              "attachments.read",
              "attachments.write",
              "attachments.destroy"
            ]
          }
        end

        config_accessor :events_for_proposals do
          [
            "draft_proposal_creation.succeeded",
            "draft_proposal_update.succeeded",
            "proposal_creation.succeeded",
            "proposal_update.succeeded",
            "proposal_state_change.succeeded"
          ]
        end

        config_accessor :events_for_oauth do
          [
            "user.created",
            "user.updated"
          ]
        end

        config_accessor :events_for_system do
          [
            "system.organizations.created",
            "system.organizations.updated",
            "system.organizations.deleted"
          ]
        end

        config_accessor :events_for_meetings do
          [
            "meetings.upcoming_reminder.succeeded"
          ]
        end

        # When true, +rest_enhancement+ with +http_cache_profile+ and relationship/meta but no +cache_time+ raises at boot.
        # When false (default), log a warning in development/test only.
        config_accessor :strict_rest_enhancement_http_cache do
          false
        end
      end
    end
  end
end
