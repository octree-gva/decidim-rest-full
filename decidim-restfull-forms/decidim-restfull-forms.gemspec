# frozen_string_literal: true

require File.expand_path("../decidim-restfull-core/lib/decidim/rest_full/version", __dir__)

Gem::Specification.new do |s|
  s.name = "decidim-restfull-forms"
  s.version = Decidim::RestFull.version
  s.authors = ["Hadrien Froger"]
  s.email = ["hadrien@octree.ch"]
  s.license = "AGPL-3.0"
  s.homepage = "https://git.octree.ch/decidim/decidim-chatbot/decidim-module-rest_full"
  s.required_ruby_version = ">= 3.2"
  s.summary = "Decidim RestFull API — questionnaires, JSON Forms, answers"
  s.description = s.summary

  s.files = Dir.chdir(__dir__) do
    Dir["{app,config,lib,spec}/**/*"].select { |f| File.file?(f) }
  end

  s.require_paths = ["lib"]

  s.add_dependency "decidim-forms", Decidim::RestFull.decidim_version
  s.add_dependency "decidim-restfull-core", Decidim::RestFull.version
  s.add_dependency "decidim-surveys", Decidim::RestFull.decidim_version

  s.metadata["rubygems_mfa_required"] = "true"
end
