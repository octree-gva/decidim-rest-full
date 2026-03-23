# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Rails engine (global mount). Wires Core into the host app and Decidim.
      # Proposals/Blogs use sibling engines; see lib/decidim/rest_full/proposals/engine.rb
      # and lib/decidim/rest_full/blogs/engine.rb.
      class Engine < ::Rails::Engine
        isolate_namespace Decidim::RestFull

        # Gem root (parent of lib/); ../../.. would incorrectly resolve to lib/ only.
        config.root = Pathname.new(File.expand_path("../../../..", __dir__))

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
        end

        initializer "rest_full.scopes" do
          Doorkeeper.configure do
            handle_auth_errors :raise
            default_scopes :public
            optional_scopes :spaces, :system, :proposals, :meetings, :debates, :pages, :blogs, :comments, :oauth, :roles
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
