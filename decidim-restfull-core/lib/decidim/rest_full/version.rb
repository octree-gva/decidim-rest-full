# frozen_string_literal: true

module Decidim
  module RestFull
    def self.version
      "0.3.4" # DO NOT UPDATE MANUALLY
    end

    def self.major_minor_version
      version.split(".")[0..1].join(".")
    end

    def self.decidim_version
      "~> 0.32.0"
    end

    # Prefer published gem once 0.15 ships. Until then Gemfile pins git upgrade-32
    # (or AWESOME_PATH). Gemspec constraint must match the git gem VERSION.
    def self.decidim_awesome_version
      ">= 0.15.0"
    end
  end
end
