# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class AccountabilityComponentSerializer < ComponentSerializer
        has_many :resources do |component, _params|
          Decidim::Accountability::Result.where(component: component).limit(50)
        end
      end
    end
  end
end
