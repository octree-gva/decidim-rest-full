# frozen_string_literal: true

# Decidim::RestFull — core gem entry (OAuth, registries, system API).
# Feature gems: sibling engines under +decidim-restfull-<feature>+ gems (included by +decidim-restfull+ metagem).
# Metagem: gem "decidim-restfull" requires all official gems.

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
require "decidim/rest_full/core/webhook_event_catalog"
require "decidim/rest_full/core/attachments_operations"
require "decidim/rest_full/core/webhook_dispatcher"
require "decidim/rest_full/core/api_exception"
require "decidim/rest_full/core/swagger_spec_paths"
require "decidim/rest_full/core/open_api_definition_paths"
require "decidim/rest_full/core/definition_registry"
require "decidim/rest_full/core/permission_registry"
require "decidim/rest_full/core/doorkeeper_config"
require "decidim/rest_full/core/route_registry"
require "decidim/rest_full/routes"
require "decidim/rest_full/routing"
require "decidim/rest_full/sync_runner"
require "decidim/rest_full/api_execution_context"
require "decidim/rest_full/api_job_payload"
require "decidim/rest_full/api_job_command_runner"
require "decidim/rest_full/core/rest_enhancement_registration"
require "decidim/rest_full/core/rest_enhancement_builder"
require "decidim/rest_full/core/serializer_additions_registry"
require "decidim/rest_full/core/http_cache/fingerprint_contributor_registry"
require "decidim/rest_full/core/http_cache/resource_show_fingerprint"
require "decidim/rest_full/core/http_cache/collection_fingerprint"
require "decidim/rest_full/extension"
require "decidim/rest_full/core/menu"
require "decidim/rest_full/core/ransackers"
require "decidim/rest_full/core/roles/role_id_codec"
require "decidim/rest_full/core/roles/roles_aggregator"
require "decidim/rest_full/core/roles/roles_writer"

require "decidim/rest_full/core/overrides/organization_client_ids_override"
require "decidim/rest_full/core/overrides/organization_extended_data_override"
require "decidim/rest_full/core/overrides/user_magic_token_override"
require "decidim/rest_full/core/overrides/user_extended_data_ransack"
require "decidim/rest_full/core/overrides/application_mailer_override"
require "decidim/rest_full/core/overrides/update_organization_form_override"
require "decidim/rest_full/core/overrides/update_organization_command_override"

module Decidim
  module RestFull
    # Root directory of decidim-restfull-core (directory containing lib/).
    ENGINE_ROOT = File.expand_path("../..", __dir__).freeze
  end
end

require "decidim/rest_full/core/engine"
require "decidim/rest_full/cli"

module Decidim
  module RestFull
    include ActiveSupport::Configurable

    def self.decidim_rest_full
      @decidim_rest_full ||= Decidim::RestFull::Core::Engine.routes.url_helpers
    end

    class WebhookFailedError < StandardError
    end

    def self.config
      Core::Configuration.config
    end

    def self.configure(&)
      Core::Configuration.configure(&)
    end

    def self.events
      c = Core::Configuration.config
      c.events_for_proposals + c.events_for_oauth + c.events_for_system + c.events_for_meetings
    end
  end
end

Decidim.register_global_engine(
  :decidim_rest_full,
  Decidim::RestFull::Core::Engine,
  at: "/"
)
