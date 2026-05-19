# frozen_string_literal: true

require "spec_helper"
require "decidim/rest_full/core/http_cache/resource_show_fingerprint"

module Decidim
  module RestFull
    module Core
      module HttpCache
        RSpec.describe ResourceShowFingerprint do
          let(:organization) { build_stubbed(:organization, id: 1) }
          let(:record) { build_stubbed(:assembly, id: 42, updated_at: Time.zone.parse("2024-01-02 12:00:00")) }

          it "builds etag and last_modified from the record" do
            fp = described_class.new(
              described_class::RequestContext.new(
                profile: :resource_show,
                organization:,
                record:,
                client_id: "client-1",
                act_as: nil,
                locales: %w(en)
              )
            )
            expect(fp.last_modified).to eq(record.updated_at)
            expect(fp.etag).to start_with('"')
            expect(fp.etag).to end_with('"')
          end
        end
      end
    end
  end
end
