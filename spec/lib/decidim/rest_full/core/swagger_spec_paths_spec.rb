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

        it "includes spec/requests by default" do
          expect(described_class.rspec_paths).to eq(["spec/requests"])
        end

        it "merges registered globs and env" do
          described_class.register("engines/foo/spec/requests")
          ENV["DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS"] = "bar/baz_spec.rb, qux/"
          expect(described_class.rspec_paths).to eq(
            ["spec/requests", "engines/foo/spec/requests", "bar/baz_spec.rb", "qux/"]
          )
        end
      end
    end
  end
end
