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
          metas[:publishable] = params[:publishable] if params.has_key? :publishable
          metas[:client_id] = proposal.rest_full_application.api_client_id if proposal.rest_full_application

          metas
        end

        attribute :title do |comp, params|
          translated_field(comp.title, params[:locales])
        end

        attribute :body do |comp, params|
          translated_field(comp.body, params[:locales])
        end

        has_one :author do |proposal, _params|
          coauthorship = proposal.coauthorships.first
          coauthorship ? coauthorship.author : nil
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
