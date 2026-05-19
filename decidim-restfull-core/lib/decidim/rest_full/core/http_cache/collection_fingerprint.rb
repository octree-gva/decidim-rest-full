# frozen_string_literal: true

require "digest"
require_relative "request_oauth_context"

module Decidim
  module RestFull
    module Core
      module HttpCache
        # Conditional GET for index-style responses (relation or enumerable scope).
        class CollectionFingerprint
          RequestContext = Struct.new(
            :profile,
            :organization,
            :relation,
            :client_id,
            :act_as,
            :locales,
            :page,
            :per_page,
            :request_filter,
            :extra,
            keyword_init: true
          )

          def self.for_request(controller, relation:, profile: :resource_index, extra: nil)
            new(
              RequestContext.new(
                profile:,
                organization: controller.send(:current_organization),
                relation:,
                client_id: RequestOAuthContext.client_id(controller),
                act_as: RequestOAuthContext.act_as_user(controller),
                locales: controller.respond_to?(:available_locales, true) ? controller.send(:available_locales) : [],
                page: controller.params[:page],
                per_page: controller.params[:per_page],
                request_filter: controller.params[:filter],
                extra:
              )
            )
          end

          def initialize(request_context)
            @ctx = request_context
            @locales = Array(@ctx.locales).map(&:to_s).sort.join(",")
            filter = @ctx.request_filter
            @filter = filter.respond_to?(:to_unsafe_h) ? filter.to_unsafe_h.to_json : filter.to_s
            @extra = @ctx.extra.to_s
          end

          def last_modified
            @last_modified ||= begin
              ts = if @ctx.relation.is_a?(ActiveRecord::Relation)
                     @ctx.relation.maximum(:updated_at)
                   else
                     Array(@ctx.relation).filter_map { |row| timestamp_for(row) }.max
                   end
              ts || Time.zone.at(0)
            end
          end

          def etag
            count = if @ctx.relation.is_a?(ActiveRecord::Relation)
                      @ctx.relation.count(:all)
                    else
                      Array(@ctx.relation).size
                    end
            input = [
              @ctx.organization.id,
              @ctx.profile,
              last_modified.to_i,
              count,
              @ctx.client_id,
              @ctx.act_as&.id,
              @locales,
              @ctx.page,
              @ctx.per_page,
              @filter,
              @extra
            ].join("/")
            %("#{Digest::SHA256.hexdigest(input)}")
          end

          private

          def timestamp_for(row)
            return row.updated_at if row.respond_to?(:updated_at) && row.updated_at.present?
            return row.created_at if row.respond_to?(:created_at) && row.created_at.present?

            nil
          end
        end
      end
    end
  end
end
