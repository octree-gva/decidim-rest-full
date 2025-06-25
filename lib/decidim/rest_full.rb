# frozen_string_literal: true

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

# Overrides
require "decidim/rest_full/overrides/organization_client_ids_override"
require "decidim/rest_full/overrides/organization_extended_data_override"

require "decidim/rest_full/overrides/proposal_client_id_override"
require "decidim/rest_full/overrides/proposals_controller_override"
require "decidim/rest_full/overrides/user_magic_token_override"

require "decidim/rest_full/overrides/user_extended_data_ransack"
require "decidim/rest_full/overrides/application_mailer_override"
require "decidim/rest_full/overrides/update_organization_form_override"

module Decidim
  module RestFull
  end
end
