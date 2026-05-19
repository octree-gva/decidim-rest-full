# frozen_string_literal: true

require "digest"

module Decidim
  module RestFull
    module HttpCache
      # Cheap validators for conditional GET on proposal show (avoids heavy window pagination SQL).
      class ProposalShowFingerprint
        def self.for_request(controller, proposal)
          new(
            organization: controller.send(:current_organization),
            proposal:,
            client_id: controller.send(:client_id),
            act_as: controller.send(:act_as),
            locales: controller.send(:available_locales),
            populate: controller.send(:populate_params),
            filter: controller.params[:filter]
          )
        end

        def initialize(organization:, proposal:, client_id:, act_as:, locales:, populate:, filter:) # rubocop:disable Metrics/ParameterLists
          @organization = organization
          @proposal = proposal
          @client_id = client_id
          @act_as = act_as
          @locales = Array(locales).map(&:to_s).sort.join(",")
          @populate = Array(populate).compact.map(&:to_s).sort.join(",")
          @filter = filter.respond_to?(:to_unsafe_h) ? filter.to_unsafe_h.to_json : filter.to_s
        end

        def last_modified
          @last_modified ||= fingerprint_last_modified
        end

        def etag
          segments = Decidim::RestFull::Core::HttpCache::FingerprintContributorRegistry.etag_segments_for(
            :proposal_show,
            proposal: @proposal,
            organization: @organization
          )
          input = [
            @organization.id,
            @proposal.id,
            last_modified.to_i,
            @client_id,
            @act_as&.id,
            @locales,
            @populate.to_s,
            @filter,
            *segments
          ].join("/")
          %("#{Digest::SHA256.hexdigest(input)}")
        end

        private

        def fingerprint_last_modified
          pid = @proposal.id
          row = Decidim::Proposals::Proposal.where(id: pid).pick(:updated_at, :decidim_component_id)
          return Time.zone.at(0) unless row

          proposal_updated, component_id = row
          component_updated = Decidim::Component.where(id: component_id).pick(:updated_at)
          votes_max = Decidim::Proposals::ProposalVote.where(decidim_proposal_id: pid).maximum(:updated_at)
          contributor_max = Decidim::RestFull::Core::HttpCache::FingerprintContributorRegistry.max_updated_at_for(
            :proposal_show,
            proposal: @proposal,
            organization: @organization
          )
          ts = [proposal_updated, component_updated, votes_max, contributor_max].compact.max
          ts || proposal_updated
        end
      end
    end
  end
end
