# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class BlogComponentSerializer < ComponentSerializer
        has_many :resources do |_component, _params|
          resources = ::Decidim::Blogs::Blog.where(component: component)
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
