# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ProposalComponentSerializer < ComponentSerializer
        has_many :resources do |component, params|
          resources = ::Decidim::Proposals::Proposal.where(component: component)
          resources = if params[:act_as].nil?
                        resources.published
                      else
                        resources.published.or(resources.where(published_at: nil, decidim_user_id: params[:act_as].id))
                      end
          resources.limit(50)
        end
      end
    end
  end
end
