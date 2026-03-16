# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    module Roles
      RSpec.describe RoleIdCodec do
        describe ".encode" do
          it "produces URL-safe base64 without padding" do
            id = described_class.encode(
              resource_type: "Decidim::Organization",
              resource_id: 1,
              user_id: 2,
              invited_at: nil,
              type: "general_admin"
            )
            expect(id).to match(/\A[A-Za-z0-9_-]+\z/)
            expect(id).not_to include("+", "/", "=")
          end
        end

        describe ".decode" do
          it "round-trips with encode" do
            payload = {
              resource_type: "Decidim::ParticipatoryProcess",
              resource_id: 10,
              user_id: 20,
              invited_at: nil,
              type: "space_administrator"
            }
            id = described_class.encode(**payload)
            decoded = described_class.decode(id)
            expect(decoded[:resource_type]).to eq("Decidim::ParticipatoryProcess")
            expect(decoded[:resource_id]).to eq(10)
            expect(decoded[:user_id]).to eq(20)
            expect(decoded[:type]).to eq("space_administrator")
          end

          it "returns nil for invalid or garbage id" do
            expect(described_class.decode("not-valid-base64!!!")).to be_nil
            expect(described_class.decode("")).to be_nil
          end
        end

        describe ".normalize_invited_at" do
          it "returns nil for nil or blank" do
            expect(described_class.normalize_invited_at(nil)).to be_nil
            expect(described_class.normalize_invited_at("")).to be_nil
          end

          it "returns iso8601 string for Time" do
            t = Time.utc(2024, 1, 15, 12, 0, 0)
            expect(described_class.normalize_invited_at(t)).to eq("2024-01-15T12:00:00Z")
          end
        end
      end
    end
  end
end
