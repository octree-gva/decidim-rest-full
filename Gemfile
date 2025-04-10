# frozen_string_literal: true

source "https://rubygems.org"

base_path = "./"
base_path = "../../" if File.basename(__dir__) == "decidim_dummy_app"
base_path = "../" if File.basename(__dir__) == "development_app"

require_relative "#{base_path}lib/decidim/rest_full/version"

DECIDIM_VERSION = Decidim::RestFull.decidim_version

gem "decidim", DECIDIM_VERSION
gem "decidim-rest_full", path: base_path

gem "bootsnap", "~> 1.4"
gem "concurrent-ruby", "1.3.4"
gem "decidim-decidim_awesome", git: "https://github.com/decidim-ice/decidim-module-decidim_awesome", tag: "v0.12.0"
gem "deface", ">= 1.9.0"
gem "pg"
gem "puma", ">= 5.5.1"
gem "uglifier", "~> 4.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", Decidim::RestFull.decidim_version
  gem "decidim-meetings", Decidim::RestFull.decidim_version
  gem "rswag-specs"
  gem "rubocop-rspec"
end

group :test do
  gem "capybara", "~> 3.40"
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
  gem "spring", "~> 4.0"
  gem "spring-watcher-listen", "~> 2.1"
end
