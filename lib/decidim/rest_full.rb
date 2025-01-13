# frozen_string_literal: true

require "rails"
require "active_support/all"
require "cancan"
require "rswag/api"
require "jsonapi/serializer"
require "api-pagination"
require "decidim/core"

require "decidim/rest_full/version"
require "decidim/rest_full/menu"
require "decidim/rest_full/engine"
require "decidim/rest_full/api_exception"

# Overrides
require "decidim/rest_full/overrides/organization_client_ids_override"
require "decidim/rest_full/overrides/proposal_client_id_override"
require "decidim/rest_full/overrides/proposals_controller_override"

require "decidim/rest_full/overrides/user_extended_data_ransack"
require "decidim/rest_full/overrides/application_mailer_override"

module Decidim
  module RestFull
    def self.decidim_rest_full
      @decidim_rest_full ||= Decidim::RestFull::Engine.routes.url_helpers
    end

    def self.docs_url
      ENV.fetch("DOCS_URL", "https://octree-gva.github.io/decidim-rest-full")
    end
  end
end
