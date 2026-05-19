# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    module Core
      RSpec.describe SwaggerSpecPaths do
        around do |example|
          described_class.reset!
          old = ENV.fetch("DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS", nil)
          ENV.delete("DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS")
          example.run
          ENV["DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS"] = old
          described_class.reset!
        end

        it "has no default paths (specs live in feature gems)" do
          expect(described_class.rspec_paths).to eq([])
        end

        it "expands request spec globs to concrete files" do
          described_class.register(
            File.join("decidim-restfull-core", "spec/requests/**/*_spec.rb")
          )
          paths = described_class.rspec_paths
          expect(paths).not_to be_empty
          expect(paths).to all(end_with("_spec.rb"))
          expect(paths.join).to include("organizations_controller_index_spec.rb")
        end

        it "omits globs with no matching files" do
          described_class.register("decidim-restfull-sortition/spec/requests/**/*_spec.rb")
          expect(described_class.rspec_paths).to eq([])
        end

        it "merges env paths when files exist" do
          core_spec = Dir.glob(
            File.join(GemSpecPaths.monorepo_root, "decidim-restfull-core/spec/requests/**/*_spec.rb")
          ).first
          skip "no core request specs in tree" unless core_spec

          rel = core_spec.delete_prefix("#{GemSpecPaths.monorepo_root}/")
          ENV["DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS"] = rel
          expect(described_class.rspec_paths).to eq([core_spec])
        end
      end
    end
  end
end
