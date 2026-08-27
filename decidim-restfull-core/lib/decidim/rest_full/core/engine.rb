# frozen_string_literal: true

# Eager require: initializer runs early; app/services is not always autoload-ready when +Extension.register+ runs.
require File.join(
  Decidim::RestFull::ENGINE_ROOT,
  "app/services/decidim/rest_full/core/participatory_process_step_activated_webhook_handler.rb"
)

module Decidim
  module RestFull
    module Core
      # Rails engine (global mount). Wires Core into the host app and Decidim.
      # Feature APIs live in decidim-restfull-* gems mounted via +Extension.register+ (see gems under the monorepo root).
      class Engine < ::Rails::Engine
        isolate_namespace Decidim::RestFull

        config.root = Decidim::RestFull::ENGINE_ROOT

        # Deface 1.9 only calls autoloader.ignore when config.autoloader == :zeitwerk,
        # which Rails 8 no longer exposes — without this, Zeitwerk expects a constant
        # for every app/overrides/*.rb file.
        initializer "rest_full.ignore_deface_overrides", before: :set_autoload_paths do
          overrides = root.join("app/overrides")
          Rails.autoloaders.main.ignore(overrides) if overrides.exist?
        end

        # Cookie sessions overflow on magic-link / confirmation (4KB limit).
        initializer "rest_full.session_store", before: :setup_default_session_store do |app|
          app.config.session_store :active_record_store
        end

        config.to_prepare do
          Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)

          Decidim::User.include(Decidim::RestFull::UserExtendedDataRansack)
          Decidim::User.include(Decidim::RestFull::UserMagicTokenOverride)
          ::Doorkeeper::TokensController.include(Decidim::RestFull::Core::ApiException::Handler)
          ::Doorkeeper::TokensController.include(Decidim::RestFull::Core::TokensAvailability)

          ::Decidim::ApplicationMailer.include(Decidim::RestFull::ApplicationMailerOverride)
          ::Decidim::System::UpdateOrganizationForm.include(Decidim::RestFull::UpdateOrganizationFormOverride)
          ::Decidim::System::UpdateOrganization.include(Decidim::RestFull::UpdateOrganizationCommandOverride)

          # Ransack attribute lists first; HasExtendedData then wraps them with extended_data.
          Decidim::RestFull::Core::Ransackers.register_ransackers!

          Decidim::Organization.include(Decidim::RestFull::Core::HasExtendedData)
          Decidim::Component.include(Decidim::RestFull::Core::HasExtendedData)

          Decidim.participatory_space_registry.manifests.each do |manifest|
            model = manifest.model_class_name.safe_constantize
            next unless model

            model.include(Decidim::RestFull::Core::HasExtendedData)
          end

          Decidim::RestFull::Core::SerializerAdditionsRegistry.apply!
        end

        initializer "rest_full.scopes" do
          ::Doorkeeper.configure do
            handle_auth_errors :raise
            default_scopes :public
            extension_scopes = Decidim::RestFull::Extension.doorkeeper_optional_scopes
            optional_scopes(*(Decidim::RestFull::Core::DoorkeeperConfig::CORE_OPTIONAL_SCOPES + extension_scopes).uniq)
            grant_flows %w(password client_credentials)

            custom_introspection_response do |token, _context|
              Decidim::RestFull::Core::DoorkeeperConfig.introspection_response(token)
            end

            resource_owner_from_credentials do |_routes|
              Decidim::RestFull::Core::DoorkeeperConfig.resource_owner_from_credentials(params:, request:)
            end
          end
        end

        initializer "rest_full.menu" do
          Decidim::RestFull::Core::Menu.register_system_menu!
        end

        initializer "rest_full.organization_settings_tab",
                    after: "decidim_toggle.organization_settings_tabs" do
          Decidim::RestFull::Core::SettingsTab.register!
        end

        initializer "rest_full.core.swagger_spec_paths" do
          Decidim::RestFull::Core::SwaggerSpecPaths.register(
            File.join(Decidim::RestFull::ENGINE_ROOT, "spec/requests/**/*_spec.rb")
          )
        end

        initializer "rest_full.permissions" do
          registry = Decidim::RestFull::Core::PermissionRegistry

          registry.register(:public, "public.component.read", group: :component)
          registry.register(:public, "public.component.extended_data.read", group: :component)
          registry.register(:public, "public.component.extended_data.update", group: :component)
          registry.register(:public, "public.space.read", group: :space)
          registry.register(:public, "public.space.extended_data.read", group: :space)
          registry.register(:public, "public.space.extended_data.update", group: :space)

          registry.register(:oauth, "oauth.magic_link", group: :oauth)
          registry.register(:oauth, "oauth.extended_data.read", group: :oauth)
          registry.register(:oauth, "oauth.extended_data.update", group: :oauth)

          registry.register(:system, "oauth.impersonate", group: :auth_type)
          registry.register(:system, "oauth.login", group: :auth_type)

          registry.register(:system, "system.organizations.read", group: :organization)
          registry.register(:system, "system.organizations.update", group: :organization)
          registry.register(:system, "system.organizations.destroy", group: :organization)
          registry.register(:system, "system.organizations.extended_data.read", group: :organization)
          registry.register(:system, "system.organizations.extended_data.update", group: :organization)

          registry.register(:system, "oauth.read", group: :user)

          registry.register(:roles, "roles.read", group: :roles)
          registry.register(:roles, "roles.write", group: :roles)

          registry.register(:webhooks, "webhooks.read", group: :webhooks)
          registry.register(:webhooks, "webhooks.write", group: :webhooks)
          registry.register(:webhooks, "webhooks.destroy", group: :webhooks)
        end

        initializer "rest_full.spaces.webhooks" do
          Decidim::RestFull::Extension.register(:spaces) do |ext|
            ext.webhook_event(
              Decidim::RestFull::Core::ParticipatoryProcessStepActivatedWebhookHandler::WEBHOOK_EVENT,
              scope: :public,
              payload_schema_ref: :space,
              schema_key: :wh_pp_step,
              trigger: "Participatory process step (phase) activated",
              example: lambda { |organization|
                ::Decidim::Api::RestFull::Core::SpaceWebhookSerializer.example_envelope(
                  organization,
                  event_name: Decidim::RestFull::Core::ParticipatoryProcessStepActivatedWebhookHandler::WEBHOOK_EVENT
                )
              }
            )
            ext.webhooks(
              Decidim::RestFull::Core::ParticipatoryProcessStepActivatedWebhookHandler::HANDLED_EVENT,
              handler: Decidim::RestFull::Core::ParticipatoryProcessStepActivatedWebhookHandler.method(:call)
            )
          end
        end

        # Same pattern as decidim_admin.mount_routes / decidim_system.mount_routes:
        # queue on Core::Engine.routes via append; RoutesReloader finalize! draws once.
        # Keep name +rest_full.draw_routes+ so feature gems can use before: safely.
        initializer "rest_full.draw_routes" do
          Decidim::RestFull::Routes.mount!
        end
      end
    end
  end
end
