# frozen_string_literal: true

# Deprecated filename: prefer decidim-restfull/decidim-restfull.gemspec
#
# Do not use +Kernel#load+ here: it returns +true+, and +Bundler::GemTasks+ (via decidim/dev/common_rake)
# expects this file to evaluate to a +Gem::Specification+.
#
# decidim-generators (AppGenerator#current_gem) regexp-parses File.read(this file); keep the next line (comment includes the assignment text).
# s.name = "decidim-restfull"

path = File.expand_path("decidim-restfull/decidim-restfull.gemspec", __dir__)
Gem::Specification.load(path)
