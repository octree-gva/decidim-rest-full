# frozen_string_literal: true

# Decidim version matrix (thoughtbot/appraisal).
# Tests: both. OpenAPI / swaggerize / yarn gen:openapi-spec: 0.32 only.
#
# Migrations differ between 0.29 and 0.32. Switching appraisals regenerates
# spec/decidim_dummy_app via bin/setup-tests (marker .decidim_appraisal). Do not
# reuse a dummy / DB from another minor — migrate-only is same-appraisal only.
#
#   bundle exec appraisal install
#   BUNDLE_GEMFILE=gemfiles/decidim_0.32.gemfile bin/setup-tests
#   BUNDLE_GEMFILE=gemfiles/decidim_0.32.gemfile bundle exec rspec
#   BUNDLE_GEMFILE=gemfiles/decidim_0.29.gemfile bin/setup-tests   # rebuilds dummy
#   BUNDLE_GEMFILE=gemfiles/decidim_0.29.gemfile bundle exec rspec

appraise "decidim-0.32" do
  gem "decidim", "~> 0.32.0"
  gem "decidim-dev", "~> 0.32.0"
  gem "decidim-conferences", "~> 0.32.0"
  gem "decidim-initiatives", "~> 0.32.0"
  gem "decidim-meetings", "~> 0.32.0"
end

appraise "decidim-0.29" do
  gem "decidim", "~> 0.29.0"
  gem "decidim-dev", "~> 0.29.0"
  gem "decidim-conferences", "~> 0.29.0"
  gem "decidim-initiatives", "~> 0.29.0"
  gem "decidim-meetings", "~> 0.29.0"

  remove_gem "decidim-decidim_awesome"
  gem "decidim-decidim_awesome", "~> 0.12.6"
end
