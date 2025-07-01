# frozen_string_literal: true

module Decidim
  module RestFull
    class ApplicationJob < ::ApplicationJob
      queue_as Decidim::RestFull.config.queue_name
      retry_on WebhookFailedError, wait: 5.seconds, attempts: 3
    end
  end
end
