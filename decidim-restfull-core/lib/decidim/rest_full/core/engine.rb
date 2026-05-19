# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Rails engine (global mount). Wires Core into the host app and Decidim.
      # Feature APIs live in decidim-restfull-* gems mounted via +Extension.register+ (see gems under the monorepo root).
      class Engine < ::Rails::Engine
        isolate_namespace Decidim::RestFull

        config.root = Decidim::RestFull::ENGINE_ROOT

        # Cookie session overflows on magic-link sign_in in the dummy app test suite.
        initializer "rest_full.test_session_store", before: :setup_default_session_store do |app|
          next unless Rails.env.test?

          app.config.session_store :cache_store, cache: ActiveSupport::Cache::MemoryStore.new
        end

        config.to_prepare do
          Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)
          Decidim::Organization.include(Decidim::RestFull::OrganizationExtendedDataOverride)

          Decidim::User.include(Decidim::RestFull::UserExtendedDataRansack)
          Decidim::User.include(Decidim::RestFull::UserMagicTokenOverride)
          ::Doorkeeper::TokensController.include(Decidim::RestFull::Core::ApiException::Handler)

          ::Decidim::ApplicationMailer.include(Decidim::RestFull::ApplicationMailerOverride)
          ::Decidim::System::UpdateOrganizationForm.include(Decidim::RestFull::UpdateOrganizationFormOverride)
          ::Decidim::System::UpdateOrganization.include(Decidim::RestFull::UpdateOrganizationCommandOverride)

          Decidim::RestFull::Core::Ransackers.register_ransackers!

          Decidim::RestFull::Routes.draw! unless Decidim::RestFull::Routes.routes_drawn?

          Decidim::RestFull::Core::SerializerAdditionsRegistry.apply!
        end

        initializer "rest_full.draw_routes", after: "rest_full.blogs.extension" do
          # Application after_initialize runs after every engine railtie (and Devise) is ready.
          Rails.application.config.after_initialize do
            Decidim::RestFull::Routes.draw!
          end
        end

        initializer "rest_full.scopes", after: "rest_full.draw_routes" do
          Doorkeeper.configure do
            handle_auth_errors :raise
            default_scopes :public
            core_optional_scopes = [:spaces, :system, :meetings, :debates, :pages, :oauth, :roles, :attachments]
            extension_scopes = Decidim::RestFull::Extension.doorkeeper_optional_scopes
            optional_scopes(*(core_optional_scopes + extension_scopes).uniq)
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

        initializer "rest_full.core.swagger_spec_paths" do
          Decidim::RestFull::Core::SwaggerSpecPaths.register(
            File.join(Decidim::RestFull::ENGINE_ROOT, "spec/requests/**/*_spec.rb")
          )
        end

        initializer "rest_full.permissions" do
          registry = Decidim::RestFull::Core::PermissionRegistry

          registry.register(:public, "public.component.read", group: :component)
          registry.register(:public, "public.space.read", group: :space)

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
          registry.register(:system, "system.users.update", group: :user)
          registry.register(:system, "system.users.destroy", group: :user)

          registry.register(:system, "system.server.restart", group: :rails)
          registry.register(:system, "system.server.exec", group: :rails)

          registry.register(:roles, "roles.read", group: :roles)
          registry.register(:roles, "roles.write", group: :roles)
        end
      end
    end
  end
end
