# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class SortitionComponentSerializer < ComponentSerializer
        has_many :resources do |component, _params|
          Decidim::Sortitions::Sortition.where(component: component).limit(50)
        end
      end
    end
  end
end
