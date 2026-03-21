# frozen_string_literal: true

module Decidim
  module RestFull
    include ActiveSupport::Configurable

    def self.decidim_rest_full
      @decidim_rest_full ||= Decidim::RestFull::Core::Engine.routes.url_helpers
    end

    class WebhookFailedError < StandardError
    end
  end
end
