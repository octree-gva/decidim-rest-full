# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # System-scope mutating operations reused by sync controllers and ApiJob worker.
      class ApiSystemOperations
        include Decidim::FormFactory

        def initialize(execution_context, params)
          @ctx = execution_context
          @params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        end

        def organizations_update!
          org = organization_from_params!
          forms = build_update_forms(org)
          apply_updates(forms, org)
          ::Decidim::Api::RestFull::Core::OrganizationSerializer.new(
            org.reload,
            params: { locales: available_locales }
          ).serializable_hash
        end

        def organization_extended_data_update!
          assert_org_matches_ctx!
          ensure_organization_extended_data
          data = @params.require(:data)
          data.permit! if data.is_a?(ActionController::Parameters)

          current_org.extended_data.update(
            data: compact_blank_recursively(
              merge_extended_data_org(data)
            )
          )
          current_org.reload
          { data: extended_data_at_path_org }
        end

        def user_extended_data_update!
          u = user_from_token!
          data = @params.require(:data)
          data.permit! if data.is_a?(ActionController::Parameters)
          u.update!(
            extended_data: compact_blank_recursively(
              merge_user_extended_data(u, data)
            )
          )
          u.reload
          { data: extended_data_at_path_user(u) }
        end

        def roles_create!
          attrs = role_params_from_body
          role = writer.create(attrs)
          ::Decidim::Api::RestFull::Core::RoleSerializer.new(role, params: serializer_params).serializable_hash
        end

        def roles_destroy!
          writer.destroy(@params.require(:id))
          nil
        end

        private

        attr_reader :ctx

        delegate :organization, :available_locales, to: :ctx

        def current_org
          organization
        end

        def assert_org_matches_ctx!
          oid = (@params[:id] || @params[:organization_id]).presence
          return if oid.blank?

          raise Decidim::RestFull::Core::ApiException::Forbidden, "Organization mismatch" if oid.to_i != organization.id
        end

        def organization_from_params!
          org = Decidim::Organization.find_by(id: @params.require(:id))
          raise Decidim::RestFull::Core::ApiException::NotFound, "Organization Not Found" unless org

          org
        end

        def serializer_params
          { host: organization.host }
        end

        def writer
          @writer ||= Decidim::RestFull::Core::Roles::RolesWriter.new(organization)
        end

        def user_from_token!
          Decidim::User.find_by!(id: ctx.doorkeeper_token.resource_owner_id, organization:)
        end

        def role_params_from_body
          data = @params.require(:data).to_unsafe_h
          attrs = data["attributes"] || data[:attributes] || {}
          {
            resource_type: attrs["resource_type"] || attrs[:resource_type],
            resource_id: attrs["resource_id"] || attrs[:resource_id],
            user_id: attrs["user_id"] || attrs[:user_id],
            type: attrs["type"] || attrs[:type]
          }.compact
        end

        def build_update_forms(org)
          system_form = system_update_form(org)
          admin_form = admin_update_form(org)
          appearance_form = appearance_update_form(org)
          [system_form, admin_form, appearance_form]
        end

        def system_update_form(org)
          form = Decidim::System::UpdateOrganizationForm.from_params(organization_payload(org))
          form.with_unconfirmed_host(org)
          validate_form(form)
          form
        end

        def admin_update_form(org)
          form(Decidim::Admin::OrganizationForm)
            .from_params(organization_payload(org))
            .with_context(current_organization: org).tap { |f| validate_form(f) }
        end

        def appearance_update_form(org)
          Decidim::Admin::OrganizationAppearanceForm
            .from_params(organization_payload(org)).tap { |f| validate_form(f) }
        end

        def apply_updates(forms, org)
          system_form, admin_form, appearance_form = forms
          system_ok = Decidim::System::UpdateOrganization.call(org.id, system_form)[:ok]
          admin_ok = Decidim::Admin::UpdateOrganization.call(admin_form, org)[:ok]
          appearance_ok = Decidim::Admin::UpdateOrganizationAppearance.call(appearance_form, org)[:ok]
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Failed to update organization" unless system_ok && admin_ok && appearance_ok
        end

        def validate_form(form)
          return if form.valid?

          update_errors = form.errors.select { |err| allowed_form_attributes.include? err.attribute.to_s }
          raise Decidim::RestFull::Core::ApiException::BadRequest, update_errors.map(&:full_message).join(". ") unless update_errors.empty?

          raise Decidim::RestFull::Core::ApiException::BadRequest, "Failed to update organization"
        end

        def allowed_form_attributes
          @allowed_form_attributes ||= transform_translated_params(transform_host_params(allowed_params)).keys
        end

        def organization_payload(org)
          transform_translated_params(
            org.attributes.deep_merge(
              transform_host_params(allowed_params)
            )
          )
        end

        def allowed_params
          @allowed_params ||= @params.require(:data).permit!.to_h.with_indifferent_access.select { |key, _value| available_params.include?(key.to_sym) }
        end

        def transform_host_params(params)
          new_host = params.delete(:host) if params.has_key?(:host)

          params.merge(unconfirmed_host: new_host)
        end

        def transform_translated_params(params)
          params.each_with_object({}) do |(key, value), result|
            if translated_fields.include?(key.to_sym) && value.is_a?(Hash)
              value.each do |locale, translated_value|
                result["#{key}_#{locale}".gsub("-", "__")] = translated_value
              end
            else
              result[key] = value
            end
          end
        end

        def translated_fields
          [:name, :description, :admin_terms_of_service_body]
        end

        def available_params
          [
            :name,
            :description,
            :admin_terms_of_service_body,
            :reference_prefix,
            :secondary_hosts,
            :default_locale,
            :available_locales,
            :send_welcome_notification,
            :host,
            :users_registration_mode,
            :force_users_to_authenticate_before_access_organization,
            :badges_enabled,
            :user_groups_enabled,
            :enable_participatory_space_filters,
            :enable_machine_translations,
            :time_zone,
            :comments_max_length,
            :rich_text_editor_in_public_views
          ]
        end

        def ensure_organization_extended_data
          return if current_org.extended_data

          current_org.create_extended_data
        end

        def extended_data_at_path_org
          return extended_data_org if object_path == "."

          object_path.split(".").reduce(extended_data_org) do |current, key|
            raise Decidim::RestFull::Core::ApiException::NotFound, "key #{object_path} not found" unless current.is_a?(Hash)
            raise Decidim::RestFull::Core::ApiException::NotFound, "key #{object_path} not found" unless current.has_key?(key)

            current[key]
          end
        end

        def merge_extended_data_org(obj)
          merged_extra = extended_data_org.deep_dup
          return merged_extra.merge(obj) if object_path == "."

          parts = object_path.split(".")
          selected = parts[..-2].reduce(merged_extra) do |current, key|
            raise Decidim::RestFull::Core::ApiException::NotFound, "key #{object_path} not found" unless current.is_a?(Hash)

            current[key] = {} unless current.has_key?(key)
            current[key]
          end
          if selected[parts.last].is_a?(Hash)
            selected[parts.last].merge!(obj)
          else
            selected[parts.last] = obj
          end
          merged_extra
        end

        def compact_blank_recursively(hash)
          hash.each_with_object({}) do |(key, value), result|
            next if value.blank?

            result[key] = value.is_a?(Hash) ? compact_blank_recursively(value) : value
            result.delete(key) if result[key].blank?
          end
        end

        def object_path
          @object_path ||= @params.require(:object_path)
        end

        def extended_data_org
          current_org.extended_data.data
        end

        def merge_user_extended_data(user, obj)
          merged_extra = user.extended_data.deep_dup
          return merged_extra.merge(obj) if object_path == "."

          parts = object_path.split(".")
          selected = parts[..-2].reduce(merged_extra) do |current, key|
            raise Decidim::RestFull::Core::ApiException::NotFound, "key #{object_path} not found" unless current.is_a?(Hash)

            current[key] = {} unless current.has_key?(key)
            current[key]
          end
          if selected[parts.last].is_a?(Hash)
            selected[parts.last].merge!(obj)
          else
            selected[parts.last] = obj
          end
          merged_extra
        end

        def extended_data_at_path_user(user)
          data = user.extended_data
          return data if object_path == "."

          object_path.split(".").reduce(data) do |current, key|
            raise Decidim::RestFull::Core::ApiException::NotFound, "key #{object_path} not found" unless current.is_a?(Hash)
            raise Decidim::RestFull::Core::ApiException::NotFound, "key #{object_path} not found" unless current.has_key?(key)

            current[key]
          end
        end
      end
    end
  end
end
