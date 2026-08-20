# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class SpaceWebhookJob < ::Decidim::RestFull::ApplicationJob
        def perform(event_name, space_id, organization_id, step_id = nil)
          organization = Decidim::Organization.find(organization_id)
          space = Decidim::ParticipatoryProcess.find(space_id)
          step = step_id.present? ? Decidim::ParticipatoryProcessStep.find(step_id) : space.try(:active_step)

          permissions_for(event_name, organization).each do |permission|
            dispatch_for_permission(permission, event_name, space, organization, step)
          end
        end

        private

        def permissions_for(event_name, organization)
          Decidim::RestFull::Core::Permission.where(permission: event_name, api_client: organization.api_clients)
        end

        def dispatch_for_permission(permission, event_name, space, organization, step)
          serializer = Decidim::Api::RestFull::Core::SpaceWebhookSerializer.new(
            space,
            event_name:,
            organization:,
            step:
          )
          payload = build_payload(permission.api_client, serializer, organization)
          return log_invalid_event(event_name, payload) unless payload.valid?

          webhook_registrations_for(permission.api_client, event_name).each do |registration|
            enqueue_webhook(registration, payload)
          end
        end

        def build_payload(api_client, serializer, organization)
          Decidim::RestFull::Core::WebhookEventForm.new(
            **serializer.event_attributes
          ).with_context(organization:, api_client:)
        end

        def log_invalid_event(event_name, payload)
          Rails.logger.warn("Invalid space webhook event #{event_name}: #{payload.errors.full_messages.join(", ")}")
        end

        def webhook_registrations_for(api_client, event_name)
          Decidim::RestFull::Core::WebhookRegistration.where(api_client_id: api_client.id).where(
            "subscriptions @> ?", [event_name].to_json
          )
        end

        def enqueue_webhook(webhook_registration, payload)
          Decidim::RestFull::Core::WebhookJob.perform_later(webhook_registration, payload.as_json, payload.timestamp.to_s)
        end
      end
    end
  end
end
