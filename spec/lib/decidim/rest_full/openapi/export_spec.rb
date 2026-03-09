# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    module OpenAPI
      RSpec.describe Export do
        describe ".build" do
          subject(:spec) { described_class.build(host: "https://example.org", locales: "en,ca") }

          it "returns a Hash with string keys" do
            expect(spec).to be_a(Hash)
            expect(spec.keys).to all(be_a(String))
          end

          it "includes openapi, info, servers, tags, components" do
            expect(spec).to include("openapi", "info", "servers", "tags", "components")
          end

          it "sets openapi version" do
            expect(spec["openapi"]).to eq("3.0.1")
          end

          it "sets server URL from host" do
            expect(spec["servers"]).to be_an(Array)
            expect(spec["servers"].first["url"]).to eq("https://example.org/api/rest_full/v0.2")
          end

          it "includes components.schemas from DefinitionRegistry" do
            schemas = spec.dig("components", "schemas")
            expect(schemas).to be_a(Hash)
            expect(schemas).to include("organization", "proposal", "blog")
          end

          it "includes components.securitySchemes" do
            schemes = spec.dig("components", "securitySchemes")
            expect(schemes).to include("credentialFlowBearer", "resourceOwnerFlowBearer")
          end

          it "includes tags" do
            expect(spec["tags"]).to be_an(Array)
            expect(spec["tags"].map { |t| t["name"] }).to include("API", "OAuth", "Organizations", "Proposals")
          end
        end
      end
    end
  end
end
