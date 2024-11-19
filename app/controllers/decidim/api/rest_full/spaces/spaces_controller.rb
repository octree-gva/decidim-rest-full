# frozen_string_literal: true

# app/controllers/api/rest_full/spaces_controller.rb
module Decidim
  module Api
    module RestFull
      module Spaces
        class SpacesController < ApplicationController
          before_action { doorkeeper_authorize! :spaces }

          def index
            # Extract only the populated fields
            only_fields = populated_fields([:id], [])

            # Query the participatory spaces
            models = Decidim.participatory_space_registry.manifests.map do |manifest|
              model = manifest.model_class_name.constantize
              arel_table = model.arel_table
              arel_table.project(*only_fields.map { |o| arel_table[o] })
            end

            # Combine models with union
            combined = models.reduce { |acc, model| acc.union(model) }

            # Paginate and render
            paginated = paginate(combined)
            render json: SpaceSerializer.new(
              paginated,
              params: { locales: available_locales },
              fields: { space: only_fields.map(&:to_sym) }
            ).serializable_hash
          end
        end
      end
    end
  end
end
