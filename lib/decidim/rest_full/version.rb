# frozen_string_literal: true

module Decidim
  module RestFull
    def self.version
      "0.0.1"
    end

    def self.decidim_version
      [">= 0.28", "<0.30"].freeze
    end
  end
end