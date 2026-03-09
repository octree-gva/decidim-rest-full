# frozen_string_literal: true

# app/controllers/api/rest_full/system/organizations_controller.rb
module Decidim
  module Api
    module RestFull
      module Organizations
        # System-scope CRUD surface for organizations, delegating to Decidim
        # system/admin commands while returning JSON API responses.
        class OrganizationsController < ApplicationController
          before_action do
            doorkeeper_authorize! :system
          end
          before_action :authorize_read!, only: [:index, :show]
          before_action :authorize_update!, only: [:update]
          include Decidim::FormFactory

          # List all organizations
          def index
            # Fetch organizations and paginate
            organizations = paginate(collection)
            # Render the response
            render json: serializable_hash(organizations)
          end

          # Show a single organization
          def show
            raise Decidim::RestFull::ApiException::NotFound, "Organization Not Found" unless organization

            # Render the response
            render json: serializable_hash(organization)
          end

          def update
            ensure_organization!
            forms = build_update_forms
            apply_updates(forms)
            render json: serializable_hash(organization.reload)
          end

          private

          def ensure_organization!
            raise Decidim::RestFull::ApiException::NotFound, "Organization Not Found" unless organization
          end

          def build_update_forms
            system_form = system_update_form
            admin_form = admin_update_form
            appearance_form = appearance_update_form
            [system_form, admin_form, appearance_form]
          end

          def system_update_form
            form = Decidim::System::UpdateOrganizationForm.from_params(organization_payload)
            form.with_unconfirmed_host(organization)
            validate_form(form)
            form
          end

          def admin_update_form
            form(Decidim::Admin::OrganizationForm)
              .from_params(organization_payload)
              .with_context(current_organization: organization).tap { |f| validate_form(f) }
          end

          def appearance_update_form
            Decidim::Admin::OrganizationAppearanceForm
              .from_params(organization_payload).tap { |f| validate_form(f) }
          end

          def apply_updates(forms)
            system_form, admin_form, appearance_form = forms
            system_ok = Decidim::System::UpdateOrganization.call(organization.id, system_form)[:ok]
            admin_ok = Decidim::Admin::UpdateOrganization.call(admin_form, organization)[:ok]
            appearance_ok = Decidim::Admin::UpdateOrganizationAppearance.call(appearance_form, organization)[:ok]
            raise Decidim::RestFull::ApiException::BadRequest, "Failed to update organization" unless system_ok && admin_ok && appearance_ok
          end

          def validate_form(form)
            return if form.valid?

            update_errors = form.errors.select { |err| allowed_form_attributes.include? err.attribute.to_s }
            raise Decidim::RestFull::ApiException::BadRequest, update_errors.map(&:full_message).join(". ") unless update_errors.empty?

            raise Decidim::RestFull::ApiException::BadRequest, "Failed to update organization"
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
            OrganizationSerializer.new(
              resource,
              params: { locales: available_locales }
            ).serializable_hash
          end

          def organization_payload
            @organization_payload ||= transform_translated_params(
              organization.attributes.deep_merge(
                transform_host_params(allowed_params)
              )
            )
          end

          def allowed_params
            @allowed_params ||= params.require(:data).permit!.to_h.with_indifferent_access.select { |key, _value| available_params.include?(key.to_sym) }
          end

          def transform_host_params(params)
            new_host = params.delete(:host) if params.has_key?(:host)

            params.merge(unconfirmed_host: new_host)
          end

          def transform_translated_params(params)
            params.each_with_object({}) do |(key, value), result|
              if translated_fields.include?(key.to_sym) && value.is_a?(Hash)
                # Handle translated fields
                value.each do |locale, translated_value|
                  result["#{key}_#{locale}".gsub("-", "__")] = translated_value
                end
              else
                # Keep non-translated values as is
                result[key] = value
              end
            end
          end

          def translated_fields
            [:name, :description, :admin_terms_of_service_body]
          end

          def available_params
            @available_params ||= [
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
