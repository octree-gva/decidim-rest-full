# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::RestFull::Core::HttpCache::FingerprintContributorRegistry do
  before { described_class.reset! }

  describe ".max_updated_at_for" do
    it "returns the maximum cache_time across contributors" do
      t1 = Time.zone.parse("2020-01-01 10:00:00")
      t2 = Time.zone.parse("2020-01-02 10:00:00")
      proposal = instance_double(Decidim::Proposals::Proposal, id: 1)
      organization = instance_double(Decidim::Organization, id: 1)

      described_class.register(
        :proposal_show,
        extension_name: :a,
        cache_time: ->(_p) { t1 }
      )
      described_class.register(
        :proposal_show,
        extension_name: :b,
        cache_time: ->(_p) { t2 }
      )

      max_ts = described_class.max_updated_at_for(
        :proposal_show,
        proposal:,
        organization:
      )
      expect(max_ts).to eq(t2)
    end
  end

  describe ".etag_segments_for" do
    it "concatenates etag_segment values" do
      proposal = instance_double(Decidim::Proposals::Proposal, id: 1)
      organization = instance_double(Decidim::Organization, id: 1)

      described_class.register(
        :proposal_show,
        extension_name: :a,
        etag_segment: ->(_p) { "seg-a" }
      )
      described_class.register(
        :proposal_show,
        extension_name: :b,
        etag_segment: ->(_p) { "seg-b" }
      )

      expect(
        described_class.etag_segments_for(
          :proposal_show,
          proposal:,
          organization:
        )
      ).to eq(%w(seg-a seg-b))
    end
  end
end
