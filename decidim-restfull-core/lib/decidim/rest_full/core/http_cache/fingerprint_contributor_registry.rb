# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      module HttpCache
        # Additive contributors for conditional GET fingerprints (e.g. proposal show ETag).
        # Feature gems register via +Decidim::RestFull::Extension#rest_enhancement+ +http_cache+ facet.
        class FingerprintContributorRegistry
          Entry = Struct.new(:extension_name, :cache_time_proc, :etag_segment_proc, keyword_init: true)

          class << self
            def reset!
              @entries = nil
            end

            def register(profile, extension_name:, cache_time: nil, etag_segment: nil)
              return if cache_time.nil? && etag_segment.nil?

              entries[profile.to_sym] << Entry.new(
                extension_name: extension_name.to_sym,
                cache_time_proc: cache_time,
                etag_segment_proc: etag_segment
              )
            end

            def max_updated_at_for(profile, proposal:, **)
              entries[profile.to_sym].filter_map do |entry|
                next unless entry.cache_time_proc

                entry.cache_time_proc.call(proposal)
              end.max
            end

            def etag_segments_for(profile, proposal:, **)
              entries[profile.to_sym].filter_map do |entry|
                next unless entry.etag_segment_proc

                entry.etag_segment_proc.call(proposal).to_s
              end
            end

            private

            def entries
              @entries ||= Hash.new { |h, k| h[k] = [] }
            end
          end
        end
      end
    end
  end
end
