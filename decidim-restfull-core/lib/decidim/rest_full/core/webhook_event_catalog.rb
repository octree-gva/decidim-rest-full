# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Single source of truth for outbound webhook event metadata (OpenAPI tag table, integrator docs).
      class WebhookEventCatalog
        Entry = Struct.new(
          :event_name,
          :scope,
          :permission_key,
          :description,
          :payload_schema_ref,
          :trigger,
          keyword_init: true
        )

        class << self
          def register(event_name, scope:, permission_key: nil, description: nil, payload_schema_ref: nil, trigger: nil) # rubocop:disable Metrics/ParameterLists
            permission_key ||= event_name
            entries[event_name] = Entry.new(
              event_name: event_name.to_s,
              scope: scope.to_s,
              permission_key: permission_key.to_s,
              description: description.to_s.presence,
              payload_schema_ref: payload_schema_ref&.to_sym,
              trigger: trigger.to_s.presence
            )
          end

          def entries
            @entries ||= {}
          end

          def all
            entries.values.sort_by(&:event_name)
          end

          def sync_from_configuration!
            cfg = Decidim::RestFull::Core::Configuration
            cfg.events_for_proposals.each do |name|
              register(
                name,
                scope: :proposals,
                trigger: "Proposal lifecycle notification",
                payload_schema_ref: :proposal_item_response
              )
            end
            cfg.events_for_oauth.each do |name|
              register(name, scope: :oauth, trigger: "User account change")
            end
            cfg.events_for_system.each do |name|
              register(name, scope: :system, trigger: "Organization admin change")
            end
            cfg.events_for_meetings.each do |name|
              register(
                name,
                scope: :meetings,
                trigger: "Upcoming meeting reminder",
                payload_schema_ref: :meeting_item_response
              )
            end
          end

          def markdown_table
            lines = [
              "| Event | Scope | Permission | Payload | Trigger |",
              "|-------|-------|------------|---------|---------|"
            ]
            all.each do |entry|
              payload = entry.payload_schema_ref ? "`#{entry.payload_schema_ref}`" : "—"
              lines << "| `#{entry.event_name}` | `#{entry.scope}` | `#{entry.permission_key}` | #{payload} | #{entry.trigger || "—"} |"
            end
            lines.join("\n")
          end

          def clear!
            @entries = {}
          end
        end
      end
    end
  end
end

Decidim::RestFull::Core::WebhookEventCatalog.sync_from_configuration!
