# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Components
        class ComponentExtendedDataController < ApplicationController
          include Decidim::Api::RestFull::ExtendedDataEndpoints

          before_action { doorkeeper_authorize! :public }
          before_action { ability.authorize! :read, ::Decidim::Component }

          private

          def extended_data_resource
            @extended_data_resource ||= begin
              component = in_visible_spaces(Decidim::Component.where(id: params.require(:id))).first
              raise Decidim::RestFull::Core::ApiException::NotFound, "Component not found" unless component

              component
            end
          end

          def extended_data_subject_class
            ::Decidim::Component
          end
        end
      end
    end
  end
end
