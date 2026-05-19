# frozen_string_literal: true

source "https://rubygems.org"

base_path = "./"
base_path = "../../" if File.basename(__dir__) == "decidim_dummy_app"
base_path = "../" if File.basename(__dir__) == "development_app"

module_root = case File.basename(__dir__)
              when "decidim_dummy_app" then File.expand_path("../..", __dir__)
              when "development_app" then File.expand_path("..", __dir__)
              else __dir__
              end
require File.join(module_root, "decidim-restfull-core/lib/decidim/rest_full/version.rb")

DECIDIM_VERSION = Decidim::RestFull.decidim_version

gem "decidim", DECIDIM_VERSION
gem "decidim-restfull", path: "#{base_path}decidim-restfull"
gem "decidim-restfull-accountabilities", path: "#{base_path}decidim-restfull-accountabilities"
gem "decidim-restfull-blogs", path: "#{base_path}decidim-restfull-blogs"
gem "decidim-restfull-budgets", path: "#{base_path}decidim-restfull-budgets"
gem "decidim-restfull-core", path: "#{base_path}decidim-restfull-core"
gem "decidim-restfull-debates", path: "#{base_path}decidim-restfull-debates"
gem "decidim-restfull-forms", path: "#{base_path}decidim-restfull-forms"
gem "decidim-restfull-meetings", path: "#{base_path}decidim-restfull-meetings"
gem "decidim-restfull-proposals", path: "#{base_path}decidim-restfull-proposals"
gem "decidim-restfull-sortition", path: "#{base_path}decidim-restfull-sortition"
gem "decidim-restfull-surveys", path: "#{base_path}decidim-restfull-surveys"

gem "bootsnap", "~> 1.4"
gem "concurrent-ruby", "1.3.4"
gem "decidim-conferences", Decidim::RestFull.decidim_version
gem "decidim-decidim_awesome", Decidim::RestFull.decidim_awesome_version
gem "decidim-initiatives", Decidim::RestFull.decidim_version
gem "decidim-meetings", Decidim::RestFull.decidim_version

gem "deface", ">= 1.9.0"
gem "pg"
gem "puma", ">= 5.5.1"
gem "uglifier", "~> 4.1"
gem "uri", ">= 1.1.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", Decidim::RestFull.decidim_version
  gem "decidim-restfull-dev", path: "#{base_path}decidim-restfull-dev"
  gem "erb_lint"
  gem "rswag-specs"
  gem "rubocop-rspec"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "rexml", "3.4.1"
  gem "rspec_junit_formatter", require: false
  gem "rspec-rails", "~> 6.0"
  gem "rubocop-faker"
  gem "selenium-webdriver"
  gem "simplecov-cobertura"
end

group :development do
  gem "faker", "~> 3.2"
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
end

gem "rswag-api", "~> 2.17"
