# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      module Ransackers
        def self.register_ransackers!
          register_component_id_ransacker!
          register_participatory_space_ransacker!
          register_user_id_ransacker!
        end

        def self.register_user_id_ransacker!
          Decidim::User.ransacker :id do |_r|
            Arel.sql('CAST("decidim_users"."id" AS VARCHAR)')
          end
        end

        def self.register_participatory_space_ransacker!
          existing_manifests = Decidim.participatory_space_registry.manifests.select do |manifest|
            manifest.model_class_name.constantize.table_exists?
          end
          existing_manifests.each do |manifest|
            model = manifest.model_class_name.constantize
            model.ransacker :manifest_name do |_r|
              Arel.sql("'#{manifest.name}'")
            end
            model.ransacker :id do |_r|
              Arel.sql("CAST(\"#{model.table_name}\".\"id\" AS VARCHAR)")
            end
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
          # Skip when DB is not available (e.g. OpenAPI doc generation, CI without DB).
        end

        def self.register_component_id_ransacker!
          Decidim::Component.ransacker :id do |_r|
            Arel.sql('CAST("decidim_components"."id" AS VARCHAR)')
          end
        end
      end
    end
  end
end
