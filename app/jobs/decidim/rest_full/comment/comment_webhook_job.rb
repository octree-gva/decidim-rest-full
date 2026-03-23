# frozen_string_literal: true

module Decidim
  module RestFull
    module Comment
      class CommentWebhookJob < ApplicationJob
        def perform(event_name, comment_id, organization_id)
          comment = Decidim::Comments::Comment.find_by(id: comment_id)
          return if comment.nil?

          organization = Decidim::Organization.find_by(id: organization_id)
          return if organization.nil?

          data = serialize_comment(comment, organization)
          permissions_for(event_name, organization).each do |permission|
            dispatch_for_permission(permission, event_name, data, organization)
          end
        end

        private

        def serialize_comment(comment, organization)
          params = serializer_params(comment, organization)
          ::Decidim::Api::RestFull::Comment::CommentSerializer.new(comment, params:).serializable_hash
        end

        def serializer_params(_comment, organization)
          {
            only: [],
            locales: organization.available_locales || Decidim.available_locales,
            host: organization.host,
            act_as: nil
          }
        end

        def permissions_for(event_name, organization)
          Decidim::RestFull::Core::Permission.where(permission: event_name, api_client: organization.api_clients)
        end

        def dispatch_for_permission(permission, event_name, data, organization)
          payload = build_payload(permission.api_client, event_name, data, organization)
          return log_invalid_event(event_name, payload) unless payload.valid?

          webhook_registrations_for(permission.api_client, event_name).each do |registration|
            enqueue_webhook(registration, payload)
          end
        end

        def build_payload(api_client, event_name, data, organization)
          Decidim::RestFull::WebhookEventForm.new(
            type: event_name,
            data:,
            timestamp: current_timestamp
          ).with_context(organization:, api_client:)
        end

        def log_invalid_event(event_name, payload)
          Rails.logger.warn("Invalid event name: #{event_name}. #{payload.errors.full_messages.join(", ")}")
        end

        def webhook_registrations_for(api_client, event_name)
          Decidim::RestFull::Core::WebhookRegistration.where(api_client_id: api_client.id).where(
            "subscriptions @> ?", [event_name].to_json
          )
        end

        def enqueue_webhook(webhook_registration, payload)
          ::Decidim::RestFull::WebhookJob.perform_later(webhook_registration, payload.as_json, current_timestamp)
        end

        def current_timestamp
          Time.current.to_i.to_s
        end
      end
    end
  end
end
