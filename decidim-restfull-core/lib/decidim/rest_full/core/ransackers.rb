# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      module Ransackers
        def self.register_ransackers!
          register_component_ransackables!
          register_component_id_ransacker!
          register_participatory_space_ransacker!
          register_user_id_ransacker!
        end

        # Decidim 0.32 Component includes SoftDeletable (deleted_at) but does not
        # define ransackable_*; Ransack 4 denies all attributes by default.
        def self.register_component_ransackables!
          return if Decidim::Component.singleton_class.method_defined?(:rest_full_ransackables_defined)

          Decidim::Component.class_eval do
            def self.ransackable_attributes(_auth_object = nil)
              %w(
                created_at deleted_at id id_value manifest_name name
                participatory_space_id participatory_space_type permissions
                published_at settings updated_at visible weight
              )
            end

            def self.ransackable_associations(_auth_object = nil)
              %w(participatory_space)
            end

            def self.rest_full_ransackables_defined
              true
            end
          end
        end

        def self.register_user_id_ransacker!
          Decidim::User.ransacker :id do |_r|
            Arel.sql('CAST("decidim_users"."id" AS VARCHAR)')
          end
          # extended_data: filter[extended_data_cont] via UserExtendedDataRansack
          extend_ransackable_attributes!(Decidim::User, %w(id extended_data))
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
            # slug is used by SpacesController search filters but omitted from
            # Decidim 0.32 public ransackable_attributes.
            extras = %w(id manifest_name)
            extras << "slug" if model.column_names.include?("slug")
            extend_ransackable_attributes!(model, extras)
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
          # Skip when DB is not available (e.g. OpenAPI doc generation, CI without DB).
        end

        def self.register_component_id_ransacker!
          Decidim::Component.ransacker :id do |_r|
            Arel.sql('CAST("decidim_components"."id" AS VARCHAR)')
          end
        end

        def self.extend_ransackable_attributes!(model, extra)
          return if model.singleton_class.method_defined?(:rest_full_ransackable_patched)

          original = model.method(:ransackable_attributes)
          model.define_singleton_method(:ransackable_attributes) do |auth_object = nil|
            (original.call(auth_object) + extra).uniq
          end
          model.define_singleton_method(:rest_full_ransackable_patched) { true }
        end
        private_class_method :extend_ransackable_attributes!
      end
    end
  end
end
