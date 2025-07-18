# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/rest_full/version"

Gem::Specification.new do |s|
  s.version = Decidim::RestFull.version
  s.authors = ["Hadrien Froger"]
  s.email = ["hadrien@octree.ch"]
  s.license = "AGPL-3.0"
  s.homepage = "https://git.octree.ch/decidim/decidim-chatbot/decidim-module-rest_full"
  s.required_ruby_version = ">= 3.0"

  s.name = "decidim-rest_full"
  s.summary = "Open Vollective in Decidim"
  s.description = "Open Collective integration for Decidim."

  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "api-pagination", "~> 6.0"
  s.add_dependency "cancancan"
  s.add_dependency "decidim-admin", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-comments", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-core", Decidim::RestFull.decidim_version
  s.add_dependency "deface", "~> 1.9"
  s.add_dependency "doorkeeper"
  s.add_dependency "jsonapi-serializer"
  s.add_dependency "rswag-api"

  s.metadata["rubygems_mfa_required"] = "true"
end
