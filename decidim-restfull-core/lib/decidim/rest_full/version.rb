# frozen_string_literal: true

module Decidim
  module RestFull
    def self.version
      "0.3.5" # DO NOT UPDATE MANUALLY
    end

    def self.major_minor_version
      version.split(".")[0..1].join(".")
    end

    # Published gemspec range. Appraisals pin a concrete minor in gemfiles/*.gemfile.
    def self.decidim_version
      [">= 0.29.0", "< 0.33"].freeze
    end

    # Covers awesome 0.12.x (Decidim 0.29) and 0.15+/git upgrade-32 (0.32).
    def self.decidim_awesome_version
      ">= 0.12.0"
    end

    def self.decidim_029?
      File.basename(ENV.fetch("BUNDLE_GEMFILE", "Gemfile")).match?(/decidim_0[._-]29/)
    end
  end
end
