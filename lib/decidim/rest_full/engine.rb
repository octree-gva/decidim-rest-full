# frozen_string_literal: true

module Decidim
  module RestFull
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::RestFull

      routes do
        get "/api/rest/docs", to: "pages#show", as: :documentation_root
        authenticate(:admin) do
          namespace "system" do
            resources :api_clients
          end
        end
        root to: "system/api_clients#index"
      end

      config.to_prepare do
        Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)
      end

      initializer "rest_full.mount_routes" do
        Decidim::Core::Engine.routes do
          mount Decidim::RestFull::Engine, at: "/", as: "rest_full"
          mount Decidim::RestFull::Root, at: "/api/rest"
        end
      end

      initializer "rest_full.scopes" do
        Doorkeeper.configure do
          # Define default and optional scopes
          default_scopes :public
          optional_scopes :spaces, :system, :proposals, :meetings, :debates, :pages

          # Enable resource owner password credentials
          grant_flows %w(password client_credentials)

          # Authenticate resource owner
          resource_owner_from_credentials do |_routes|
            # forbid system scope, exclusive to credential flow
            raise ::Doorkeeper::Errors::DoorkeeperError, "can not request system scope with ROPC flow" if (params["scope"] || "").include? "system"

            current_organization = request.env["decidim.current_organization"]
            Decidim::RestFull::ApiClient.find_by(
              uid: params.require("client_id"),
              organization: current_organization
            )
            user = Decidim::User.find_by(
              nickname: params.require("username"),
              organization: current_organization
            )
            user
          end
        end
      end
      initializer "rest_full.menu" do
        Decidim::RestFull::Menu.register_system_menu!
      end
    end
  end
end
