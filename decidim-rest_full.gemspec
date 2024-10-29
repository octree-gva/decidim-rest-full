# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/rest_full/version"

Gem::Specification.new do |s|
  s.version = Decidim::RestFull.version
  s.authors = ["Hadrien Froger"]
  s.email = ["hadrien@octree.ch"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/octree-gva/decidim-module-rest_full"
  s.required_ruby_version = ">= 3.0"

  s.name = "decidim-rest_full"
  s.summary = "Open Vollective in Decidim"
  s.description = "Open Collective integration for Decidim."

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(app/ config/ db/ lib/ Rakefile README.md))
    end
  end

  s.require_paths = ["lib"]
  s.add_dependency "api-pagination", "~> 6.0"
  s.add_dependency "decidim-admin", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-comments", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-core", Decidim::RestFull.decidim_version
  s.add_dependency "grape", "~> 2.2.0"
  s.add_dependency "grape-entity", "~> 1.0.1"
  s.add_dependency "grape-swagger", ">= 2.0.0"
  s.add_dependency "grape-swagger-entity", "~> 0.5.5"
  s.add_dependency "kaminari"

  s.metadata["rubygems_mfa_required"] = "true"
end
