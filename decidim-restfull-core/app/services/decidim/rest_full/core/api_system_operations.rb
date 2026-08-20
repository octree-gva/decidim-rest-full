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
          org = org.reload
          ::Decidim::Api::RestFull::Core::OrganizationSerializer.new(
            org,
            params: { locales: org.available_locales.map(&:to_sym) }
          ).serializable_hash
        end

        def organization_extended_data_update!
          assert_org_matches_ctx!
          raw = @params.respond_to?(:to_unsafe_h) ? @params.to_unsafe_h : @params.to_h
          @params = ActionController::Parameters.new(
            raw.merge(
              "resource_type" => "Decidim::Organization",
              "resource_id" => current_org.id
            )
          )
          resource_extended_data_update!
        end

        def resource_extended_data_update!
          resource = find_extended_data_resource!
          ensure_extended_data_row(resource)
          data = @params.require(:data)
          data.permit! if data.is_a?(ActionController::Parameters)

          merged = compact_blank_recursively(
            merge_extended_data_hash(resource.extended_data_hash, data)
          )
          assert_extended_data_payload_size!(merged)

          resource.extended_data.update(data: merged)
          resource.reload
          { data: ExtendedDataAtPath.fetch(resource.extended_data_hash, object_path) }
        end

        def user_extended_data_update!
          u = user_from_token!
          data = @params.require(:data)
          data.permit! if data.is_a?(ActionController::Parameters)
          merged = compact_blank_recursively(
            merge_user_extended_data(u, data)
          )
          assert_extended_data_payload_size!(merged)
          u.update!(extended_data: merged)
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
          [system_update_form(org), admin_update_form(org)]
        end

        def system_update_form(org)
          form = Decidim::System::UpdateOrganizationForm.from_model(org)
          apply_system_form_updates!(form, org)
          form.with_unconfirmed_host(org)
          validate_form(form)
          form
        end

        def apply_system_form_updates!(form, org)
          payload = organization_payload(org)
          %w(host default_locale users_registration_mode force_users_to_authenticate_before_access_organization).each do |attr|
            form.public_send("#{attr}=", payload[attr]) if payload.has_key?(attr)
          end
          form.secondary_hosts = payload["secondary_hosts"] if payload.has_key?("secondary_hosts")
          apply_translated_form_updates!(form, org, payload, *translated_fields_for(org))
          form.unconfirmed_host = payload["unconfirmed_host"] if payload.has_key?("unconfirmed_host")
        end

        # Assign full locale hashes onto the form so Decidim UpdateOrganization does not
        # wipe unsubmitted locales (Admin form accessors often follow Decidim.available_locales only).
        def apply_translated_form_updates!(form, org, payload, *fields)
          fields.each do |field|
            next unless org.respond_to?(field)
            next unless form.respond_to?("#{field}=")

            existing = org.public_send(field)
            values = org.available_locales.index_with do |locale|
              key = "#{field}_#{locale}"
              if payload.has_key?(key)
                payload[key]
              else
                locale_value(existing, locale) || locale_value(form.public_send(field), locale)
              end
            end
            form.public_send("#{field}=", values) if values.values.any?
          end
        end

        def locale_value(hash, locale)
          return nil unless hash.is_a?(Hash)

          hash[locale] || hash[locale.to_s] || hash[locale.to_sym]
        end

        def admin_update_form(org)
          payload = organization_payload(org)
          form = form(Decidim::Admin::OrganizationForm).from_params(payload).with_context(current_organization: org)
          # Force merged translations: from_params may ignore locales outside Decidim.available_locales.
          apply_translated_form_updates!(form, org, payload, :name, :description, :admin_terms_of_service_body)
          preserve_decidim_029_booleans!(form, org, payload)
          validate_form(form)
          form
        end

        # 0.29 Organization columns are NOT NULL; Admin forms default missing/unmapped booleans to nil.
        def preserve_decidim_029_booleans!(form, org, payload)
          %w(user_groups_enabled enable_participatory_space_filters).each do |attr|
            next unless org.respond_to?(attr)
            next unless form.respond_to?("#{attr}=")

            value = if payload.has_key?(attr) || payload.has_key?(attr.to_sym)
                      payload[attr] || payload[attr.to_sym]
                    else
                      org.public_send(attr)
                    end
            next if value.nil?

            form.public_send("#{attr}=", value)
          end
        end

        def apply_updates(forms, org)
          snapshots = translation_snapshots(org)
          system_form, admin_form = forms
          system_ok = Decidim::System::UpdateOrganization.call(org.id, system_form)[:ok]
          admin_ok = Decidim::Admin::UpdateOrganization.call(admin_form, org)[:ok]
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Failed to update organization" unless system_ok && admin_ok

          org.reload
          # ponytail: Admin TranslatableAttributes only define name_<locale> for Decidim.available_locales;
          # org may have more locales — restore any wiped unsubmitted locale values.
          restore_unsubmitted_translations!(org, snapshots)
        end

        def translation_snapshots(org)
          translated_fields_for(org).index_with do |field|
            stringify_locale_keys((org.public_send(field) || {}).except("machine_translations", :machine_translations))
          end
        end

        def restore_unsubmitted_translations!(org, snapshots)
          dirty = false
          snapshots.each do |field, before|
            next if before.blank?

            submitted = allowed_params[field] || allowed_params[field.to_s]
            submitted = submitted.is_a?(Hash) ? stringify_locale_keys(submitted) : {}
            merged = before.merge(submitted)
            current = stringify_locale_keys((org.public_send(field) || {}).except("machine_translations", :machine_translations))
            next if current == merged

            org.public_send("#{field}=", merged)
            dirty = true
          end
          org.save! if dirty
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
          updates = transform_host_params(allowed_params.deep_dup)
          merged = stringify_top_keys(organization_baseline_attributes(org))
          merge_translated_locale_updates!(merged, updates)
          updates.each do |key, value|
            next if translated_fields.include?(key.to_sym)

            merged[key.to_s] = value
          end
          coerce_secondary_hosts!(merged)
          transform_translated_params(merged)
        end

        # Deep-merge locale hashes with string keys so partial updates (e.g. only +en+)
        # keep existing locales (e.g. +fr+) instead of wiping them via key-type mismatch.
        def merge_translated_locale_updates!(baseline, updates)
          translated_fields.each do |field|
            update_key = updates.keys.find { |k| k.to_sym == field }
            next unless update_key

            update_val = updates.delete(update_key)
            next unless update_val.is_a?(Hash)

            base_val = stringify_locale_keys(baseline[field.to_s] || {})
            # Drop machine_translations from API merge surface; Decidim owns that key.
            base_val = base_val.except("machine_translations")
            baseline[field.to_s] = base_val.merge(stringify_locale_keys(update_val).except("machine_translations"))
          end
        end

        def stringify_top_keys(hash)
          hash.each_with_object({}) { |(key, value), acc| acc[key.to_s] = value }
        end

        def stringify_locale_keys(hash)
          hash.each_with_object({}) { |(locale, value), acc| acc[locale.to_s] = value }
        end

        def organization_baseline_attributes(org)
          hash = available_params.each_with_object({}) do |key, acc|
            next unless org.respond_to?(key)

            acc[key.to_s] = org.public_send(key)
          end
          hash["id"] = org.id
          hash["users_registration_mode"] = org.users_registration_mode.to_s
          hash["secondary_hosts"] = Array(org.secondary_hosts).join("\n")
          hash["machine_translation_display_priority"] = org.machine_translation_display_priority
          hash
        end

        def coerce_secondary_hosts!(payload)
          return unless payload["secondary_hosts"].is_a?(Array)

          payload["secondary_hosts"] = payload["secondary_hosts"].join("\n")
        end

        def allowed_params
          @allowed_params ||= @params.require(:data).permit!.to_h.with_indifferent_access.select { |key, _value| available_params.include?(key.to_sym) }
        end

        def transform_host_params(params)
          return params unless params.has_key?(:host) || params.has_key?("host")

          new_host = params.delete(:host)
          new_host = params.delete("host") if new_host.nil? && params.has_key?("host")
          params.merge("unconfirmed_host" => new_host)
        end

        def transform_translated_params(params)
          params.each_with_object({}) do |(key, value), result|
            if translated_fields.include?(key.to_sym) && value.is_a?(Hash)
              value.each do |locale, translated_value|
                next if locale.to_s == "machine_translations"

                result["#{key}_#{locale}".to_s.gsub("-", "__")] = translated_value
              end
            else
              result[key.to_s] = value
            end
          end
        end

        def translated_fields_for(org)
          translated_fields.select { |field| org.respond_to?(field) }
        end

        def translated_fields
          [:name, :short_name, :description, :admin_terms_of_service_body]
        end

        def available_params
          [
            :name,
            :short_name,
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
            # Present on Decidim 0.29 (NOT NULL); removed from 0.32 models — baseline skips via respond_to?.
            :user_groups_enabled,
            :enable_participatory_space_filters,
            :enable_machine_translations,
            :time_zone,
            :comments_max_length,
            :rich_text_editor_in_public_views
          ]
        end

        def ensure_extended_data_row(resource)
          return if resource.extended_data

          resource.create_extended_data!
        end

        def find_extended_data_resource!
          type = @params.require(:resource_type).to_s
          id = @params.require(:resource_id)

          case type
          when "Decidim::Organization"
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Organization mismatch" if id.to_i != organization.id

            organization
          when "Decidim::Component"
            find_component_for_extended_data!(id)
          when "Decidim::Proposals::Proposal"
            find_proposal_for_extended_data!(id)
          when "Decidim::Meetings::Meeting"
            find_meeting_for_extended_data!(id)
          else
            find_space_for_extended_data!(type, id)
          end
        end

        def find_component_for_extended_data!(id)
          component = Decidim::Component.find_by(id:)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Component not found" unless component
          raise Decidim::RestFull::Core::ApiException::NotFound, "Component not found" unless component_in_organization?(component)

          component
        end

        def find_proposal_for_extended_data!(id)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Proposal not found" unless defined?(::Decidim::Proposals::Proposal)

          proposal = ::Decidim::Proposals::Proposal.find_by(id:)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Proposal not found" unless proposal
          raise Decidim::RestFull::Core::ApiException::NotFound, "Proposal not found" unless component_in_organization?(proposal.component)

          proposal
        end

        def find_meeting_for_extended_data!(id)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Meeting not found" unless defined?(::Decidim::Meetings::Meeting)

          meeting = ::Decidim::Meetings::Meeting.find_by(id:)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Meeting not found" unless meeting
          raise Decidim::RestFull::Core::ApiException::NotFound, "Meeting not found" unless component_in_organization?(meeting.component)

          meeting
        end

        def find_space_for_extended_data!(type, id)
          klass = type.safe_constantize
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Unknown resource type" unless klass
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Unknown resource type" unless space_model?(klass)

          space = klass.find_by(id:, organization:)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Space not found" unless space

          space
        end

        def component_in_organization?(component)
          return false unless component

          space = component.participatory_space
          return false unless space

          org_id = if space.respond_to?(:decidim_organization_id)
                     space.decidim_organization_id
                   elsif space.respond_to?(:organization)
                     space.organization&.id
                   end
          org_id == organization.id
        end

        def space_model?(klass)
          Decidim.participatory_space_registry.manifests.any? do |manifest|
            manifest.model_class_name == klass.name
          end
        end

        def merge_extended_data_hash(base_hash, obj)
          merged_extra = base_hash.deep_dup
          obj = obj.to_unsafe_h if obj.respond_to?(:to_unsafe_h)
          obj = obj.deep_stringify_keys if obj.respond_to?(:deep_stringify_keys)
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

        def assert_extended_data_payload_size!(data)
          max = Decidim::RestFull.config.max_extended_data_payload_bytes
          return if max.blank? || !max.positive?

          size = data.to_json.bytesize
          return if size <= max

          raise Decidim::RestFull::Core::ApiException::BadRequest,
                "extended_data exceeds maximum size of #{max} bytes"
        end

        def object_path
          @object_path ||= @params.require(:object_path)
        end

        def merge_user_extended_data(user, obj)
          merge_extended_data_hash(user.extended_data.deep_dup, obj)
        end

        def extended_data_at_path_user(user)
          ExtendedDataAtPath.fetch(user.extended_data, object_path)
        end
      end
    end
  end
end
