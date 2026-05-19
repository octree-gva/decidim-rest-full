# frozen_string_literal: true

return if defined?(Decidim::RestFull::Test::DEFINITIONS_LOADED)

Decidim::RestFull::Test::DEFINITIONS_LOADED = true

# Core-owned schemas only. Feature gems register barrels via Extension#open_api_definitions.
require_relative "definitions/shared"
require_relative "definitions/core"
require_relative "../core/open_api_definition_paths"

Decidim::RestFull::Core::OpenApiDefinitionPaths.load_all!

Decidim::RestFull::Core::DefinitionRegistry.finalize_openapi_component_resource_schema!
