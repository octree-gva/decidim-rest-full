# frozen_string_literal: true

module Decidim
  module RestFull
    def self.version
      "0.3.1" # DO NOT UPDATE MANUALLY
    end

    def self.major_minor_version
      version.split(".")[0..1].join(".")
    end

    def self.decidim_version
      "~> 0.29"
    end

    def self.decidim_awesome_version
      "0.12.6"
    end
  end
end
