# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["NODE_ENV"] ||= "test"
ENV["DISABLE_SPRING"] = "1"
ENV["ENGINE_ROOT"] = File.dirname(__dir__)

require "decidim/dev"

dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))
unless File.directory?(dummy_app_path)
  warn "Dummy app not found at #{dummy_app_path}. Run: bin/setup-tests (or bundle exec rake test_app)"
  exit(1)
end
Decidim::Dev.dummy_app_path = dummy_app_path

require "decidim/dev/test/base_spec_helper"
require "decidim/core/test/factories"

# Apply RestFull API routes to Core (dummy app may not mount our engine, or mount order can miss registration).
gem_config = File.expand_path("../config/routes.rb", __dir__)
load gem_config if File.file?(gem_config)

# Keep Decidim.available_locales in sync with I18n for tests so translated
# attributes and generated *_<locale> helpers line up.
Decidim.available_locales = I18n.available_locales

# Ensure engine constants (controllers, models, jobs, commands) are loaded before spec files run
Rails.application.eager_load!

require "decidim/rest_full/test/definitions"
require "decidim/rest_full/test/global_context"
require "decidim/rest_full/test/on_api_endpoint_methods"

if ENV["SIMPLECOV"]
  require "simplecov"
  require "simplecov-cobertura"

  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  SimpleCov.start
end

Bullet.add_safelist type: :counter_cache, class_name: "Decidim::Proposals::Proposal", association: :coauthorships if defined?(Bullet)
