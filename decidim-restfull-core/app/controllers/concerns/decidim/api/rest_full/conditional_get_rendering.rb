# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      # Shared conditional GET (ETag / Last-Modified) before +render json:+.
      # Subclasses override +conditional_get_fingerprint+ or pass +fingerprint:+ explicitly.
      module ConditionalGetRendering
        extend ActiveSupport::Concern

        private

        # @param payload [Hash] JSON body for +render json:+
        # @param fingerprint [Object, nil] object responding to +etag+ and +last_modified+
        # @param status [Symbol] HTTP status when rendering body (default +:ok+)
        def render_json_with_conditional_get(payload, fingerprint: conditional_get_fingerprint, status: :ok, **render_opts)
          if fingerprint && !stale?(
            etag: fingerprint.etag,
            last_modified: fingerprint.last_modified,
            public: false,
            template: false
          )
            return
          end

          render json: payload, status:, **render_opts
        end

        # Optional hook for +show+ (and similar) actions. Return +nil+ to skip validators.
        def conditional_get_fingerprint
          nil
        end

        def collection_fingerprint_for(relation, extra: nil)
          Decidim::RestFull::Core::HttpCache::CollectionFingerprint.for_request(
            self,
            relation:,
            extra:
          )
        end

        def resource_fingerprint_for(record)
          Decidim::RestFull::Core::HttpCache::ResourceShowFingerprint.for_request(self, record)
        end
      end
    end
  end
end
