# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class WebhookJob < ::Decidim::RestFull::ApplicationJob
        def perform(webhook_registration, payload, timestamp)
          webhook_registration.send_webhook(payload, timestamp)
        end
      end
    end
  end
end
