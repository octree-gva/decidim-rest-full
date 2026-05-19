# frozen_string_literal: true

require "spec_helper"
require "decidim/rest_full/core/gem_spec_paths"

module Decidim
  module RestFull
    module Core
      RSpec.describe GemSpecPaths do
        it "lists every monorepo feature gem" do
          expect(described_class::GEMS).to include(
            "decidim-restfull-core",
            "decidim-restfull-proposals",
            "decidim-restfull-forms"
          )
        end

        it "resolves request spec globs under the monorepo root" do
          glob = described_class.request_spec_glob("decidim-restfull-core")
          expect(glob).to eq(
            File.join(described_class.spec_dir("decidim-restfull-core"), "requests/**/*_spec.rb")
          )
        end
      end
    end
  end
end
