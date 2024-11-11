# frozen_string_literal: true

module Decidim
    module RestFull
      module Spaces
        class Space < Grape::API
          def self.available_fields
            [:slug, :title, :subtitle, :short_description, :description, :published_at, :id]
          end

          helpers ParamsHelper
  
          resource :spaces do
            desc "Visible Spaces", {
              entity: "::Decidim::RestFull::Entities::SpaceEntity",
              tags: ["spaces"],
              is_array: true
            }
            params do
              use :translated, :populated
            end
            paginate
            route_setting :swagger, root: "spaces"
            get "/" do
              only = populated([:id])
              models = Decidim.participatory_space_registry.manifests.map do |manifest| 
                model = manifest.model_class_name.constantize
                arel_table = model.arel_table
                arel_table.project(*only.map {|o| arel_table[o]})
              end
              first_model = models[0]
              others = models[1..]
              combined = first_model
              others.each do |o|
                combined = combined.union(o)
              end
              Entities::SpaceEntity.represent(
                paginate(combined),
                only: populated([:id]),
                locales: locales
              )
            end
  
          end
        end
      end
    end
  end
  