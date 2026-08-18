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
            model = manifest.model_class_name.safe_constantize
            next false unless model

            model.table_exists?
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
        # ponytail: db:create / appraisal switch may boot against missing DB or a
        # prior-minor schema (Rails 8 enum needs columns that are not migrated yet).
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
          nil
        rescue RuntimeError => e
          raise unless e.message.include?("Undeclared attribute type for enum")
        end

        def self.register_component_id_ransacker!
          Decidim::Component.ransacker :id do |_r|
            Arel.sql('CAST("decidim_components"."id" AS VARCHAR)')
          end
        end

        # Idempotent: multiple callers (space ransackers + HasExtendedData) may add extras.
        def self.extend_ransackable_attributes!(model, extra)
          unless model.singleton_class.method_defined?(:rest_full_ransackable_patched)
            extras = []
            model.define_singleton_method(:rest_full_ransackable_extras) { extras }
            original = model.method(:ransackable_attributes)
            model.define_singleton_method(:ransackable_attributes) do |auth_object = nil|
              (original.call(auth_object) + rest_full_ransackable_extras).uniq
            end
            model.define_singleton_method(:rest_full_ransackable_patched) { true }
          end

          model.rest_full_ransackable_extras.concat(Array(extra))
          model.rest_full_ransackable_extras.uniq!
        end
      end
    end
  end
end
