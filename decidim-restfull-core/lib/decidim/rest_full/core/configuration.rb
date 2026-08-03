# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class Configuration
        include ActiveSupport::Configurable

        FEATURE_PERMISSION_SETS = {
          "decidim-restfull-blogs" => { "blogs" => %w(blogs.read blogs.write blogs.destroy) },
          "decidim-restfull-proposals" => { "proposals" => %w(proposals.read proposals.draft proposals.vote) },
          "decidim-restfull-debates" => { "debates" => %w(debates.read) },
          "decidim-restfull-budgets" => { "budgets" => %w(budgets.read) },
          "decidim-restfull-surveys" => {
            "surveys" => %w(
              surveys.read surveys.questionnaires.read surveys.questions.manage
              surveys.answers.read surveys.answers.submit surveys.answers.destroy
            )
          },
          "decidim-restfull-accountabilities" => { "accountability" => %w(accountability.read) },
          "decidim-restfull-meetings" => { "meetings" => %w(meetings.read) }
        }.freeze

        class << self
          def default_available_permissions
            always_available_permissions.merge(feature_permissions).tap do |permissions|
              add_feature_events(permissions, "proposals", default_events_for_proposals)
              add_feature_events(permissions, "meetings", default_events_for_meetings)
            end
          end

          def default_events_for_proposals
            return [] unless Gem.loaded_specs.has_key?("decidim-restfull-proposals")

            %w(
              draft_proposal_creation.succeeded draft_proposal_update.succeeded
              proposal_creation.succeeded proposal_update.succeeded proposal_state_change.succeeded
            )
          end

          def default_events_for_meetings
            return [] unless Gem.loaded_specs.has_key?("decidim-restfull-meetings")

            %w(meetings.upcoming_reminder.succeeded)
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
              "attachments" => %w(attachments.read attachments.write attachments.destroy)
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

          def feature_permissions
            FEATURE_PERMISSION_SETS.each_with_object({}) do |(gem, permissions), available|
              available.merge!(permissions) if Gem.loaded_specs.has_key?(gem)
            end
          end

          def add_feature_events(permissions, scope, events)
            permissions[scope]&.concat(events)
          end
        end

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

        config_accessor :available_permissions do
          Decidim::RestFull::Core::Configuration.default_available_permissions
        end

        config_accessor :events_for_proposals do
          Decidim::RestFull::Core::Configuration.default_events_for_proposals
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
          Decidim::RestFull::Core::Configuration.default_events_for_meetings
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
