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
gem "puma", ">= 5.5.1"
gem "uglifier", "~> 4.1"

gem "deface", ">= 1.9.0"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", Decidim::RestFull.decidim_version
  gem "decidim-meetings", Decidim::RestFull.decidim_version
  gem "rswag-specs"
  gem "rubocop-rspec"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "rspec-rails", "~> 6.0"
  gem "rubocop-faker"
  gem "selenium-webdriver"
end

group :development do
  gem "faker", "~> 3.2"
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 4.0"
  gem "spring-watcher-listen", "~> 2.1"
end
