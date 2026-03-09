# frozen_string_literal: true

# Decidim::RestFull provides a REST API for Decidim (OAuth2, JSON:API-style resources).
# Entry point: this file. Load order matters for RouteRegistry and overrides.
# See CONTRIBUTING.md for vocabulary, entry points, and where the "magic" lives.

require "rails"
require "active_support/all"
require "cancan"
require "rswag/api"
require "jsonapi/serializer"
require "api-pagination"
require "decidim/core"

require "decidim/rest_full/rest_full"
require "decidim/rest_full/version"
require "decidim/rest_full/webhook_dispatcher"
require "decidim/rest_full/menu"
require "decidim/rest_full/engine"
require "decidim/rest_full/api_exception"
require "decidim/rest_full/definition_registry"
require "decidim/rest_full/permission_registry"
require "decidim/rest_full/configuration"
require "decidim/rest_full/doorkeeper_config"
require "decidim/rest_full/route_registry"
require "decidim/rest_full/openapi/export"
require "decidim/rest_full/cli"
require "decidim/rest_full/ransackers"

# Overrides
require "decidim/rest_full/overrides/organization_client_ids_override"
require "decidim/rest_full/overrides/organization_extended_data_override"
require "decidim/rest_full/overrides/proposal_client_id_override"
require "decidim/rest_full/overrides/proposals_controller_override"
require "decidim/rest_full/overrides/user_magic_token_override"

require "decidim/rest_full/overrides/user_extended_data_ransack"
require "decidim/rest_full/overrides/application_mailer_override"
require "decidim/rest_full/overrides/update_organization_form_override"
require "decidim/rest_full/overrides/update_organization_command_override"

module Decidim
  module RestFull
    def self.config
      Configuration.config
    end

    def self.configure
      Configuration.configure
    end

    def self.events
      Configuration.events_for_proposals + Configuration.events_for_oauth + Configuration.events_for_system
    end
  end
end
