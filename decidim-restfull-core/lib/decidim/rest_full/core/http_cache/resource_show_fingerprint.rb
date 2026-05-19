# frozen_string_literal: true

require "digest"
require_relative "request_oauth_context"

module Decidim
  module RestFull
    module Core
      module HttpCache
        # Default conditional GET fingerprint for a single ActiveRecord row (+updated_at+).
        # Feature gems can register extra +etag_segment+ via +FingerprintContributorRegistry+.
        class ResourceShowFingerprint
          RequestContext = Struct.new(
            :profile,
            :organization,
            :record,
            :client_id,
            :act_as,
            :locales,
            keyword_init: true
          )

          def self.for_request(controller, record, profile: :resource_show)
            new(
              RequestContext.new(
                profile:,
                organization: controller.send(:current_organization),
                record:,
                client_id: RequestOAuthContext.client_id(controller),
                act_as: RequestOAuthContext.act_as_user(controller),
                locales: controller.respond_to?(:available_locales, true) ? controller.send(:available_locales) : []
              )
            )
          end

          def initialize(request_context)
            @ctx = request_context
            @locales = Array(@ctx.locales).map(&:to_s).sort.join(",")
          end

          def last_modified
            @last_modified ||= [
              @ctx.record.updated_at,
              FingerprintContributorRegistry.max_updated_at_for(
                @ctx.profile,
                proposal: @ctx.record,
                organization: @ctx.organization
              )
            ].compact.max
          end

          def etag
            segments = FingerprintContributorRegistry.etag_segments_for(
              @ctx.profile,
              proposal: @ctx.record,
              organization: @ctx.organization
            )
            input = [
              @ctx.organization.id,
              @ctx.record.class.name,
              @ctx.record.id,
              last_modified.to_i,
              @ctx.client_id,
              @ctx.act_as&.id,
              @locales,
              *segments
            ].join("/")
            %("#{Digest::SHA256.hexdigest(input)}")
          end
        end
      end
    end
  end
end
