# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/rest_full/version"

Gem::Specification.new do |s|
  s.version = Decidim::RestFull.version
  s.authors = ["Hadrien Froger"]
  s.email = ["hadrien@octree.ch"]
  s.license = "AGPL-3.0"
  s.homepage = "https://git.octree.ch/decidim/decidim-chatbot/decidim-module-rest_full"
  s.required_ruby_version = ">= 3.2"

  s.name = "decidim-rest_full"
  s.summary = "Rest Full API for Decidim"
  s.description = "Rest Full API for Decidim"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE*", "Rakefile", "README*", "CHANGELOG*"].reject do |f|
    f.match(%r{^(test|spec|features|website)/})
  end

  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "api-pagination", "~> 6.0"
  s.add_dependency "cancancan"
  s.add_dependency "decidim-admin", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-blogs", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-comments", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-core", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-decidim_awesome", Decidim::RestFull.decidim_awesome_version
  s.add_dependency "decidim-proposals", Decidim::RestFull.decidim_version
  s.add_dependency "deface", "~> 1.9"
  s.add_dependency "doorkeeper"
  s.add_dependency "jsonapi-serializer"
  s.add_dependency "rswag-api", "~> 2.17"

  s.metadata["rubygems_mfa_required"] = "true"
end
