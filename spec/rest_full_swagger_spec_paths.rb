# frozen_string_literal: true

# Loaded by bin/swaggerize before RSpec (no full Rails boot). Registers every gem-local request spec glob.
require "decidim/rest_full/core/swagger_spec_paths"
require "decidim/rest_full/core/gem_spec_paths"

Decidim::RestFull::Core::GemSpecPaths.register_swagger_paths!
