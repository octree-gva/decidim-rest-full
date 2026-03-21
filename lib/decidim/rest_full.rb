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

require "decidim/rest_full/core/configuration"
require "decidim/rest_full/core/webhook_dispatcher"
require "decidim/rest_full/core/api_exception"
require "decidim/rest_full/core/swagger_spec_paths"
require "decidim/rest_full/core/definition_registry"
require "decidim/rest_full/core/permission_registry"
require "decidim/rest_full/core/doorkeeper_config"
require "decidim/rest_full/core/route_registry"
require "decidim/rest_full/core/menu"
require "decidim/rest_full/core/ransackers"
require "decidim/rest_full/core/roles/role_id_codec"
require "decidim/rest_full/core/roles/roles_aggregator"
require "decidim/rest_full/core/roles/roles_writer"

# Core overrides
require "decidim/rest_full/core/overrides/organization_client_ids_override"
require "decidim/rest_full/core/overrides/organization_extended_data_override"
require "decidim/rest_full/core/overrides/user_magic_token_override"
require "decidim/rest_full/core/overrides/user_extended_data_ransack"
require "decidim/rest_full/core/overrides/application_mailer_override"
require "decidim/rest_full/core/overrides/update_organization_form_override"
require "decidim/rest_full/core/overrides/update_organization_command_override"

# Proposals overrides (before proposals engine +to_prepare+)
require "decidim/rest_full/proposals/proposal_client_id_override"
require "decidim/rest_full/proposals/proposals_controller_override"

require "decidim/rest_full/proposals/engine"
require "decidim/rest_full/blogs/engine"
require "decidim/rest_full/core/engine"

require "decidim/rest_full/cli"

module Decidim
  module RestFull
    def self.config
      Core::Configuration.config
    end

    def self.configure(&)
      Core::Configuration.configure(&)
    end

    def self.events
      c = Core::Configuration.config
      c.events_for_proposals + c.events_for_oauth + c.events_for_system
    end
  end
end

Decidim.register_global_engine(
  :decidim_rest_full,
  Decidim::RestFull::Core::Engine,
  at: "/"
)
