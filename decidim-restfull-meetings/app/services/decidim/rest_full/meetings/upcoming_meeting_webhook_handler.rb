# frozen_string_literal: true

module Decidim
  module RestFull
    module Meetings
      # Dispatches webhook-capable payloads when Decidim publishes +decidim.events.meetings.upcoming_meeting+.
      module UpcomingMeetingWebhookHandler
        HANDLED_EVENT = "decidim.events.meetings.upcoming_meeting"

        def self.call(event_name, data)
          return unless event_name == HANDLED_EVENT

          payload = normalize_payload(data)
          meeting = payload[:resource]
          return unless meeting.is_a?(::Decidim::Meetings::Meeting)

          webhook_event = Decidim::RestFull.config.events_for_meetings&.first

          MeetingWebhookJob.perform_later(webhook_event, meeting.id, meeting.component.organization.id) if webhook_event.present?
        end

        def self.normalize_payload(data)
          case data
          when Hash
            data.symbolize_keys
          when ActiveSupport::Notifications::Event
            data.payload.symbolize_keys
          else
            {}
          end
        end

        private_class_method :normalize_payload
      end
    end
  end
end
