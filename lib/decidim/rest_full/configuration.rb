# frozen_string_literal: true

module Decidim
  module RestFull
    class Configuration
      include ActiveSupport::Configurable

      config_accessor :loadbalancer_ips do
        ips = ENV.fetch("DECIDIM_REST_LOADBALANCER_IPS", "127.0.0.1, ::1").split(",").map(&:strip)
        ips.map { |ip| IPAddr.new(ip) }.map(&:to_s)
      end

      config_accessor :queue_name do
        ENV.fetch("DECIDIM_REST_QUEUE_NAME", "default")
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
    end
  end
end
