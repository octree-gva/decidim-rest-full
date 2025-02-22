# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ProposalSerializer < ResourceSerializer
        def self.default_meta(proposal)
          scope = proposal.component.scope || proposal.participatory_space.scope
          metas = {
            published: proposal.published?
          }
          metas[:scope] = scope.id if scope
          metas
        end

        meta do |proposal, params|
          metas = default_meta(proposal)
          metas[:has_more] = params[:has_more] if params.has_key? :has_more
          metas[:next] = params[:next].id.to_s if params.has_key?(:next) && params[:next]
          metas[:prev] = params[:prev].id.to_s if params.has_key?(:prev) && params[:prev]
          metas[:count] = params[:count] if params.has_key? :count
          metas[:client_id] = proposal.rest_full_application.api_client_id if proposal.rest_full_application
          vote_manifest = proposal.component.settings[:awesome_voting_manifest]

          if params[:act_as]
            vote = proposal.votes.where(decidim_author_id: params[:act_as].id).last
            metas[:voted] = if vote_manifest && vote && Object.const_defined?("Decidim::DecidimAwesome") && Decidim::DecidimAwesome.enabled?(:weighted_proposal_voting)
                              match = Decidim::DecidimAwesome::VoteWeight.find_by(proposal_vote_id: vote.id)
                              weight_value = match ? match.weight : 1
                              { weight: weight_value }
                            elsif vote
                              { weight: 1 }
                            end
          end

          metas
        end

        attribute :title do |comp, params|
          translated_field(comp.title, params[:locales])
        end

        attribute :body do |comp, params|
          translated_field(comp.body, params[:locales])
        end

        has_one :state, if: (proc do |proposal|
          proposal.state
        end), meta: (proc do |proposal, _params|
          { token: proposal.state }
        end) do |proposal, _params|
          proposal.proposal_state
        end

        has_one :author, if: (proc do |proposal|
          proposal.coauthorships.count.positive?
        end) do |proposal, _params|
          proposal.coauthorships.first.author
        end

        has_many :coauthors, meta: (proc do |proposal, _params|
          { count: proposal.coauthorships.count }
        end) do |proposal, _params|
          proposal.coauthorships.map do |coauthorship, _params|
            coauthorship.author
          end
        end
      end
    end
  end
end
