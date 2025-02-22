# frozen_string_literal: true

module Decidim
  module RestFull
    def self.version
      "0.1.4" # DO NOT UPDATE MANUALLY
    end

    def self.major_minor_version
      version.split(".")[0..1].join(".")
    end

    def self.decidim_version
      [">= 0.28", "<0.30"].freeze
    end
  end
end
