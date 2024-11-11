# frozen_string_literal: true

require "rails"
require "active_support/all"

require "grape"
require "grape-entity"
require "grape-swagger"
require "grape-swagger-entity"
require "api-pagination"
require "decidim/core"

require "decidim/rest_full/version"
require "decidim/rest_full/menu"
# Overrides
require "decidim/rest_full/overrides/organization_client_ids"

# Helpers
require "decidim/rest_full/params_helper"

# Entites
require "decidim/rest_full/entities/meta_entity"
require "decidim/rest_full/entities/translated_entity"
require "decidim/rest_full/entities/organization_entity"

# APIS
require "decidim/rest_full/system/api"
require "decidim/rest_full/spaces/api"
require "decidim/rest_full/root"
require "decidim/rest_full/engine"

module Decidim
  module RestFull
    def self.decidim_rest_full
      @decidim_rest_full ||= Decidim::RestFull::Engine.routes.url_helpers
    end
  end
end
