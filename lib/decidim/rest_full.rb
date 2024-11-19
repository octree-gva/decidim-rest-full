# frozen_string_literal: true

require "rails"
require "active_support/all"

require "rswag/api"
require "jsonapi/serializer"
require "api-pagination"
require "decidim/core"

require "decidim/rest_full/version"
require "decidim/rest_full/menu"
require "decidim/rest_full/engine"
require "decidim/rest_full/api_exception"

# Overrides
require "decidim/rest_full/overrides/organization_client_ids"

module Decidim
  module RestFull
    def self.decidim_rest_full
      @decidim_rest_full ||= Decidim::RestFull::Engine.routes.url_helpers
    end

    def self.docs_url
      ENV.fetch("DOCS_URL", "http://localhost:3232/decidim-rest-full")
    end
  end
end
