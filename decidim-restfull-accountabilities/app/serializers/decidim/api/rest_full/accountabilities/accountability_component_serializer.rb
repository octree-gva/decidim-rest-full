# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Accountabilities
        class AccountabilityComponentSerializer < ::Decidim::Api::RestFull::Core::ComponentSerializer
          def self.resources_for(component, _act_as)
            Decidim::Accountability::Result.where(component:)
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
end
