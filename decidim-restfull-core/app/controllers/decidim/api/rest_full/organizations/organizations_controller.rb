# frozen_string_literal: true

# app/controllers/api/rest_full/system/organizations_controller.rb
module Decidim
  module Api
    module RestFull
      module Organizations
        # System-scope CRUD surface for organizations, delegating to Decidim
        # system/admin commands while returning JSON API responses.
        class OrganizationsController < ApplicationController
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action do
            doorkeeper_authorize! :system
          end
          before_action :authorize_read!, only: [:index, :show]
          before_action :authorize_update!, only: [:update, :update_sync]
          include Decidim::FormFactory

          # List all organizations
          def index
            organizations = paginate(collection)
            payload = serializable_hash(organizations)
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(organizations))
          end

          def show
            raise Decidim::RestFull::Core::ApiException::NotFound, "Organization Not Found" unless organization

            payload = serializable_hash(organization)
            render_json_with_conditional_get(payload, fingerprint: resource_fingerprint_for(organization))
          end

          def update
            enqueue_rest_full_api_job!("organizations#update")
          end

          def update_sync
            render json: (Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Core::ApiSystemOperations.new(api_execution_context, params).organizations_update!
            end)
          end

          private

          def ensure_organization!
            raise Decidim::RestFull::Core::ApiException::NotFound, "Organization Not Found" unless organization
          end

          def build_update_forms
            [system_update_form, admin_update_form]
          end

          def system_update_form
            form = Decidim::System::UpdateOrganizationForm.from_model(organization)
            apply_system_form_updates!(form)
            form.with_unconfirmed_host(organization)
            validate_form(form)
            form
          end

          def apply_system_form_updates!(form)
            payload = organization_payload
            %w(host default_locale users_registration_mode force_users_to_authenticate_before_access_organization).each do |attr|
              form.public_send("#{attr}=", payload[attr]) if payload.has_key?(attr)
            end
            form.secondary_hosts = payload["secondary_hosts"] if payload.has_key?("secondary_hosts")
            apply_translated_form_updates!(form, payload, :name, :short_name)
            form.unconfirmed_host = payload["unconfirmed_host"] if payload.has_key?("unconfirmed_host")
          end

          def apply_translated_form_updates!(form, payload, *fields)
            fields.each do |field|
              locales = organization.available_locales
              values = locales.index_with do |locale|
                key = "#{field}_#{locale}"
                payload.has_key?(key) ? payload[key] : form.public_send(field).try(:[], locale)
              end
              form.public_send("#{field}=", values) if values.values.any?
            end
          end

          def admin_update_form
            form(Decidim::Admin::OrganizationForm)
              .from_params(organization_payload)
              .with_context(current_organization: organization).tap { |f| validate_form(f) }
          end

          def apply_updates(forms)
            system_form, admin_form = forms
            system_ok = Decidim::System::UpdateOrganization.call(organization.id, system_form)[:ok]
            admin_ok = Decidim::Admin::UpdateOrganization.call(admin_form, organization)[:ok]
            raise Decidim::RestFull::Core::ApiException::BadRequest, "Failed to update organization" unless system_ok && admin_ok
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

          def authorize_update!
            authorize! :update, ::Decidim::Organization
          end

          def authorize_destroy!
            authorize! :destroy, ::Decidim::Organization
          end

          def organization
            @organization ||= collection.find(params.require(:id))
          end

          def serializable_hash(resource)
            Core::OrganizationSerializer.new(
              resource,
              params: { locales: available_locales }
            ).serializable_hash
          end

          def organization_payload
            @organization_payload ||= begin
              merged = organization_baseline_attributes.deep_merge(
                transform_host_params(allowed_params)
              )
              coerce_secondary_hosts!(merged)
              transform_translated_params(merged)
            end
          end

          # Only writable API fields — full AR attributes break System/Admin forms
          # (smtp/omniauth/file_upload blobs, secondary_hosts array vs string, etc.).
          def organization_baseline_attributes
            hash = available_params.each_with_object({}) do |key, acc|
              next unless organization.respond_to?(key)

              acc[key.to_s] = organization.public_send(key)
            end
            hash["id"] = organization.id
            hash["users_registration_mode"] = organization.users_registration_mode.to_s
            hash["secondary_hosts"] = Array(organization.secondary_hosts).join("\n")
            hash["machine_translation_display_priority"] = organization.machine_translation_display_priority
            hash
          end

          def coerce_secondary_hosts!(payload)
            return unless payload["secondary_hosts"].is_a?(Array)

            payload["secondary_hosts"] = payload["secondary_hosts"].join("\n")
          end

          def allowed_params
            @allowed_params ||= params.require(:data).permit!.to_h.with_indifferent_access.select { |key, _value| available_params.include?(key.to_sym) }
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
                # Handle translated fields
                value.each do |locale, translated_value|
                  result["#{key}_#{locale}".to_s.gsub("-", "__")] = translated_value
                end
              else
                # Keep non-translated values as is
                result[key.to_s] = value
              end
            end
          end

          def translated_fields
            [:name, :short_name, :description, :admin_terms_of_service_body]
          end

          def available_params
            @available_params ||= [
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

          def authorize_create!
            authorize! :create, ::Decidim::Organization
          end

          def authorize_read!
            authorize! :read, ::Decidim::Organization
          end

          def collection
            Decidim::Organization.all
          end
        end
      end
    end
  end
end
