# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Spaces
        class SpaceExtendedDataController < ApplicationController
          include Decidim::Api::RestFull::ExtendedDataEndpoints

          before_action { doorkeeper_authorize! :public }
          before_action { ability.authorize! :read, ::Decidim::ParticipatorySpaceManifest }

          private

          def extended_data_resource
            @extended_data_resource ||= begin
              manifest = params.require(:manifest_name)
              model = space_model_from(manifest)
              space = visible_scope_for(model, act_as).find_by(id: params.require(:id))
              raise Decidim::RestFull::Core::ApiException::NotFound, "Space not found" unless space

              space
            end
          end
        end
      end
    end
  end
end
