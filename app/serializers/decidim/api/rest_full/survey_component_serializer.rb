# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class SurveyComponentSerializer < ComponentSerializer
        has_many :resources do |component, _params|
          Decidim::Surveys::Survey.where(component: component).limit(50)
        end
      end
    end
  end
end
