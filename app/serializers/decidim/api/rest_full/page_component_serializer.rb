# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class PageComponentSerializer < ComponentSerializer
        def self.resources_for(component, act_as)
          Decidim::Pages::Page.where(decidim_component_id: component.id)
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
