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

# Do not load gem specs vendored under the dummy app (bundle path leakage).
RSpec.configure do |config|
  config.exclude_pattern = "spec/decidim_dummy_app/vendor/**/*_spec.rb"
end

# Dummy app: draw after environment boot if Decidim route reload cleared API routes (same as to_prepare).
Decidim::RestFull::Routes.draw! unless Decidim::RestFull::Routes.routes_drawn?

# Force a known set of locales so factories and I18n stay valid (dummy app may use different defaults).
test_locales = %w(en fr es)
I18n.available_locales = test_locales.map(&:to_sym)
I18n.enforce_available_locales = false
Rails.application.config.i18n.available_locales = test_locales
Rails.application.config.i18n.default_locale = :en
Decidim.available_locales = test_locales
Decidim.default_locale = :en

Rails.application.eager_load!

require "decidim/rest_full/test/definitions"
require "decidim/rest_full/test/global_context"
require "decidim/rest_full/test/on_api_endpoint_methods"

Decidim::RestFull.configure do |config|
  config.strict_rest_enhancement_http_cache = true if ENV["CI"] == "1"
end

if ENV["SIMPLECOV"]
  require "simplecov"
  require "simplecov-cobertura"

  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  SimpleCov.start
end

Bullet.add_safelist type: :counter_cache, class_name: "Decidim::Proposals::Proposal", association: :coauthorships if defined?(Bullet)
