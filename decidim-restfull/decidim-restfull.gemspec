# frozen_string_literal: true

require File.expand_path("../decidim-restfull-core/lib/decidim/rest_full/version", __dir__)

Gem::Specification.new do |s|
  s.name = "decidim-restfull"
  s.version = Decidim::RestFull.version
  s.authors = ["Hadrien Froger"]
  s.email = ["hadrien@octree.ch"]
  s.license = "AGPL-3.0"
  s.homepage = "https://git.octree.ch/decidim/decidim-chatbot/decidim-module-rest_full"
  s.required_ruby_version = ">= 3.2"
  s.summary = "Decidim RestFull API (metagem — core + official feature gems)"
  s.description = "Requires decidim-restfull-core and official decidim-restfull-* feature gems."

  s.files = Dir.chdir(__dir__) do
    Dir["lib/**/*"].select { |f| File.file?(f) }
  end

  s.require_paths = ["lib"]

  s.add_dependency "decidim-restfull-accountabilities", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-blogs", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-budgets", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-core", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-debates", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-forms", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-meetings", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-proposals", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-sortition", Decidim::RestFull.version
  s.add_dependency "decidim-restfull-surveys", Decidim::RestFull.version

  s.metadata["rubygems_mfa_required"] = "true"
end
