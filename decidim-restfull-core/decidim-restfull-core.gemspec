# frozen_string_literal: true

require File.expand_path("lib/decidim/rest_full/version", __dir__)

Gem::Specification.new do |s|
  s.name = "decidim-restfull-core"
  s.version = Decidim::RestFull.version
  s.authors = ["Hadrien Froger"]
  s.email = ["hadrien@octree.ch"]
  s.license = "AGPL-3.0"
  s.homepage = "https://git.octree.ch/decidim/decidim-chatbot/decidim-module-rest_full"
  s.required_ruby_version = ">= 3.2"
  s.summary = "Decidim RestFull API — core (OAuth, registries, system routes)"
  s.description = s.summary

  s.files = Dir.chdir(__dir__) do
    Dir["{app,config,db,lib,spec}/**/*", "README.md"].select { |f| File.file?(f) }
  end

  s.require_paths = ["lib"]

  s.add_dependency "api-pagination", "~> 6.0"
  s.add_dependency "cancancan"
  s.add_dependency "decidim-admin", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-core", Decidim::RestFull.decidim_version
  s.add_dependency "deface", "~> 1.9"
  s.add_dependency "doorkeeper"
  s.add_dependency "jsonapi-serializer"
  s.add_dependency "rswag-api", "~> 2.17"

  s.metadata["rubygems_mfa_required"] = "true"
end
