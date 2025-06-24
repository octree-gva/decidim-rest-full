# frozen_string_literal: true

module Decidim
  module RestFull
    class WebhookJob < ApplicationJob
      def perform(webhook_registration, payload, timestamp)
        webhook_registration.send_webhook(payload, timestamp)
      end
    end
  end
end
