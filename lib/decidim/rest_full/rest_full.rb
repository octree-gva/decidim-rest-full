# frozen_string_literal: true

module Decidim
  module RestFull
    include ActiveSupport::Configurable

    def self.decidim_rest_full
      @decidim_rest_full ||= Decidim::RestFull::Engine.routes.url_helpers
    end

    config_accessor :docs_url do
      ENV.fetch("DOCS_URL", "https://octree-gva.github.io/decidim-rest-full")
    end

    config_accessor :events_for_proposals do
      [
        "draft_proposal_creation.succeeded",
        "draft_proposal_update.succeeded",
        "proposal_creation.succeeded",
        "proposal_update.succeeded",
        "proposal_state_change.succeeded"
      ]
    end

    class WebhookFailedError < StandardError
    end
  end
end
