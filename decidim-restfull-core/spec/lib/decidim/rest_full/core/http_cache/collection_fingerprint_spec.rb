# frozen_string_literal: true

require "spec_helper"
require "decidim/rest_full/core/http_cache/collection_fingerprint"

module Decidim
  module RestFull
    module Core
      module HttpCache
        RSpec.describe CollectionFingerprint do
          let(:organization) { build_stubbed(:organization, id: 7) }
          let(:relation) { instance_double(ActiveRecord::Relation) }
          let(:updated_at) { Time.zone.parse("2024-06-01 10:00:00") }

          before do
            allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
            allow(relation).to receive(:maximum).with(:updated_at).and_return(updated_at)
            allow(relation).to receive(:count).and_raise("COUNT must not be used in CollectionFingerprint")
          end

          def build_fp(**overrides)
            described_class.new(
              described_class::RequestContext.new(
                {
                  profile: :resource_index,
                  organization:,
                  relation:,
                  client_id: "client-1",
                  act_as: nil,
                  locales: %w(en fr),
                  page: 1,
                  per_page: 20,
                  order: "published_at",
                  order_direction: "asc",
                  request_filter: { "state_eq" => "accepted" },
                  extra: nil
                }.merge(overrides)
              )
            )
          end

          it "builds etag without calling relation.count" do
            fp = build_fp
            expect(fp.last_modified).to eq(updated_at)
            expect(fp.etag).to match(/\A"[0-9a-f]{64}"\z/)
          end

          it "changes etag when page changes" do
            expect(build_fp(page: 1).etag).not_to eq(build_fp(page: 2).etag)
          end

          it "changes etag when order changes" do
            expect(build_fp(order: "published_at").etag).not_to eq(build_fp(order: "rand").etag)
          end
        end
      end
    end
  end
end
