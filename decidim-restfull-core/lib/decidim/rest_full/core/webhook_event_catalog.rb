# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Single source of truth for outbound webhook event metadata (OpenAPI tag table, integrator docs).
      # Feature gems register via +Extension#webhook_event+; core oauth/system sync from Configuration.
      class WebhookEventCatalog
        Entry = Struct.new(
          :event_name,
          :scope,
          :permission_key,
          :description,
          :payload_schema_ref,
          :trigger,
          :schema_key,
          :example,
          keyword_init: true
        )

        class << self
          def register(event_name, scope:, example:, permission_key: nil, description: nil, payload_schema_ref: nil, trigger: nil, schema_key: nil) # rubocop:disable Metrics/ParameterLists
            raise ArgumentError, "example callable required for #{event_name}" unless example.respond_to?(:call)

            permission_key ||= event_name
            name = event_name.to_s
            entries[name] = Entry.new(
              event_name: name,
              scope: scope.to_s,
              permission_key: permission_key.to_s,
              description: description.to_s.presence,
              payload_schema_ref: payload_schema_ref&.to_sym,
              trigger: trigger.to_s.presence,
              schema_key: (schema_key || default_schema_key(name)).to_s,
              example:
            )
          end

          def entries
            @entries ||= {}
          end

          def all
            entries.values.sort_by(&:event_name)
          end

          def find(event_name)
            entries[event_name.to_s]
          end

          def schema_key_for(event_name)
            entry = find(event_name)
            raise KeyError, "Unknown webhook event: #{event_name}" unless entry

            entry.schema_key
          end

          # Sample envelope for GET /webhook_events/{event_type} (callable supplied at registration).
          def example_payload_for(event_name, organization:)
            entry = find(event_name)
            raise KeyError, "Unknown webhook event: #{event_name}" unless entry

            entry.example.call(organization)
          end

          def sync_from_configuration!
            cfg = Decidim::RestFull::Core::Configuration
            cfg.events_for_oauth.each do |name|
              register(
                name,
                scope: :oauth,
                trigger: "User account change",
                payload_schema_ref: :user,
                schema_key: "wh_#{name.tr(".", "_").delete_suffix("_succeeded")}",
                example: oauth_example_for(name)
              )
            end
            cfg.events_for_system.each do |name|
              register(
                name,
                scope: :system,
                trigger: "Organization admin change",
                payload_schema_ref: :organization,
                schema_key: "wh_#{name.tr(".", "_").delete_suffix("_succeeded")}",
                example: system_example_for(name)
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

          private

          # "proposal_creation.succeeded" → "wh_proposal_creation"
          def default_schema_key(event_name)
            "wh_#{event_name.to_s.sub(/\.succeeded\z/, "").tr(".", "_")}"
          end

          def oauth_example_for(event_name)
            lambda do |organization|
              Decidim::Api::RestFull::Core::UserWebhookSerializer.example_envelope(
                organization,
                event_name:
              )
            end
          end

          def system_example_for(event_name)
            lambda do |organization|
              Decidim::Api::RestFull::Core::OrganizationWebhookSerializer.example_envelope(
                organization,
                event_name:
              )
            end
          end
        end
      end
    end
  end
end

Decidim::RestFull::Core::WebhookEventCatalog.sync_from_configuration!
