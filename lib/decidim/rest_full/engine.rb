# frozen_string_literal: true

module Decidim
  module RestFull
    # Rails engine. Wires the module into the host app and Decidim.
    # - to_prepare: includes our overrides into Decidim/Doorkeeper classes and registers ransackers.
    # - rest_full.webhooks: subscribes to Decidim events and dispatches to WebhookDispatcher.
    # - rest_full.scopes: configures Doorkeeper (scopes, grant flows, introspection, ROPC).
    # - rest_full.menu: adds items to the system admin menu.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::RestFull

      # Engine file lives in lib/ but app/, config/, db/ live at gem root. Use gem path so it
      # works for path gems, published gems, and any bundle location.
      gem_root = Pathname.new(Gem.loaded_specs["decidim-rest_full"].full_gem_path)
      # Only append to path keys that exist on Engine (app/jobs, app/commands, etc. are not default)
      %w(app/controllers app/models app/views db/migrate config).each do |key|
        config.paths[key] << gem_root.join(key)
      end
      config.autoload_paths << gem_root.join("app/jobs")
      config.autoload_paths << gem_root.join("app/commands")
      config.autoload_paths << gem_root.join("app/forms")
      config.autoload_paths << gem_root.join("app/serializers")

      config.to_prepare do
        # Organization: has_many :api_clients for OAuth client registration per org.
        Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)
        # Organization: has_one :extended_data and ensures it on create (e.g. unconfirmed_host).
        Decidim::Organization.include(Decidim::RestFull::OrganizationExtendedDataOverride)
        # Proposal: has_one :rest_full_application (external client id mapping).
        Decidim::Proposals::Proposal.include(Decidim::RestFull::ProposalClientIdOverride)
        # ProposalsController: proposal_draft excludes proposals already linked to external clients.
        Decidim::Proposals::ProposalsController.include(Decidim::RestFull::ProposalsControllerOverride)

        # User: ransacker on extended_data for API filtering.
        Decidim::User.include(Decidim::RestFull::UserExtendedDataRansack)
        # User: has_one magic_token and rest_full_generate_magic_token for passwordless auth.
        Decidim::User.include(Decidim::RestFull::UserMagicTokenOverride)
        # Doorkeeper tokens: rescue_from API exceptions → consistent JSON error responses.
        ::Doorkeeper::TokensController.include(Decidim::RestFull::ApiException::Handler)

        # Mailer: no delivery to @example.org; publish notification for webhooks.
        ::Decidim::ApplicationMailer.include(Decidim::RestFull::ApplicationMailerOverride)
        # System org form: unconfirmed_host attribute and validation for host change flow.
        ::Decidim::System::UpdateOrganizationForm.include(Decidim::RestFull::UpdateOrganizationFormOverride)
        # System org update: persist unconfirmed_host in extended_data and enqueue sync job.
        ::Decidim::System::UpdateOrganization.include(Decidim::RestFull::UpdateOrganizationCommandOverride)

        Decidim::RestFull::Ransackers.register_ransackers!
      end

      initializer "rest_full.webhooks" do
        ActiveSupport::Notifications.subscribe(/decidim\.events\./) do |event_name, data|
          WebhookDispatcher.instance.handle_proposals(event_name, data)
        end
        ActiveSupport::Notifications.subscribe(/decidim\.proposals\./) do |event_name, data|
          WebhookDispatcher.instance.handle_proposals(event_name, data)
        end
      end

      initializer "rest_full.scopes" do
        Doorkeeper.configure do
          handle_auth_errors :raise
          default_scopes :public
          optional_scopes :spaces, :system, :proposals, :meetings, :debates, :pages, :blogs, :oauth
          grant_flows %w(password client_credentials)

          custom_introspection_response do |token, _context|
            Decidim::RestFull::DoorkeeperConfig.introspection_response(token)
          end

          resource_owner_from_credentials do |_routes|
            Decidim::RestFull::DoorkeeperConfig.resource_owner_from_credentials(params:, request:)
          end
        end
      end

      initializer "rest_full.menu" do
        Decidim::RestFull::Menu.register_system_menu!
      end

      initializer "rest_full.permissions" do
        registry = Decidim::RestFull::PermissionRegistry

        registry.register(:public, "public.component.read", group: :component)
        registry.register(:public, "public.space.read", group: :space)

        registry.register(:proposals, "proposals.read", group: :proposals)
        registry.register(:proposals, "proposals.draft", group: :proposals)
        registry.register(:proposals, "proposals.vote", group: :proposals)

        registry.register(:blogs, "blogs.read", group: :blogs)

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
      end
    end
  end
end
