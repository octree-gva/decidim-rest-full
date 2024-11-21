# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class BudgetComponentSerializer < ComponentSerializer
        has_many :resources do |_component, _params|
          Decidim::Budgets::Budget.where(decidim_component_id: component.id)
        end
      end
    end
  end
end
