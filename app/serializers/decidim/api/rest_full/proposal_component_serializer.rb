# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ProposalComponentSerializer < ComponentSerializer
        def self.resources_for(component, act_as)
          resources = ::Decidim::Proposals::Proposal.where(component: component)
          if act_as.nil?
            resources.published
          else
            resources.joins(:coauthorships).published.or(
              resources.joins(:coauthorships).where(
                published_at: nil,
                coauthorships: { decidim_author_id: act_as.id }
              )
            )
          end
        end

        has_many :resources, meta: (proc do |component, params|
          { count: resources_for(component, params[:act_as]).count }
        end) do |component, params|
          resources_for(component, params[:act_as]).limit(50)
        end
      end
    end
  end
end
