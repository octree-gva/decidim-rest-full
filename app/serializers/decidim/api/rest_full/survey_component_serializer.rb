# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class SurveyComponentSerializer < ComponentSerializer
        def self.resources_for(component, act_as)
          Decidim::Surveys::Survey.where(decidim_component_id: component.id)
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
