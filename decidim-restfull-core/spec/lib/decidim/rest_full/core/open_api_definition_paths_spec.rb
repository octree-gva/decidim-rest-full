# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    module Core
      RSpec.describe OpenApiDefinitionPaths do
        around do |example|
          described_class.reset!
          old = ENV.fetch("DECIDIM_REST_FULL_OPENAPI_DEFINITION_PATHS", nil)
          ENV.delete("DECIDIM_REST_FULL_OPENAPI_DEFINITION_PATHS")
          example.run
          ENV["DECIDIM_REST_FULL_OPENAPI_DEFINITION_PATHS"] = old
          described_class.reset!
        end

        it "loads a registered barrel file" do
          barrel = File.join(
            "decidim-restfull-surveys",
            "lib/decidim/rest_full/surveys/test_definitions.rb"
          )
          full = File.join(GemSpecPaths.monorepo_root, barrel)
          skip "surveys definitions barrel missing" unless File.file?(full)

          described_class.register(barrel)
          expect { described_class.load_all! }.not_to raise_error
          expect(described_class).to be_loaded
        end

        it "expands globs to definition barrels" do
          described_class.register(
            File.join("decidim-restfull-surveys", "lib/decidim/rest_full/surveys/test_definitions.rb")
          )
          paths = described_class.expand_paths(described_class.extra)
          expect(paths).not_to be_empty
          expect(paths.join).to include("surveys/test_definitions.rb")
        end

        it "merges env paths when files exist" do
          barrel = Dir.glob(
            File.join(GemSpecPaths.monorepo_root, "decidim-restfull-*/lib/decidim/rest_full/*/test_definitions.rb")
          ).first
          skip "no feature test_definitions barrels in tree" unless barrel

          rel = barrel.delete_prefix("#{GemSpecPaths.monorepo_root}/")
          ENV["DECIDIM_REST_FULL_OPENAPI_DEFINITION_PATHS"] = rel
          paths = described_class.expand_paths(described_class.env_paths)
          expect(paths).to eq([barrel])
        end
      end
    end
  end
end
