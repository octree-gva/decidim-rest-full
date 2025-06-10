# frozen_string_literal: true

module Decidim
  module RestFull
    class WebhookRegistrationForm < Decidim::Form
      mimic :webhook_registration
      attribute :url, String
      attribute :subscriptions, Array

      validates :url, presence: true
      validates :subscriptions, presence: true
      validate :valid_schema?
      validate :valid_subscriptions?

      private

      def valid_schema?
        errors.add(:url, "must be a valid HTTPS URL") unless url.start_with?("https://")
      end

      def valid_subscriptions?
        subscriptions.each do |subscription|
          errors.add(:subscriptions, "Subscription  to #{subscription} is not allowed") unless available_events.include?(subscription)
        end
      end

      def available_events
        @available_events ||= client_api.permissions.events.pluck(:permission)
      end

      def client_api
        @client_api ||= context.api_client
      end
    end
  end
end
