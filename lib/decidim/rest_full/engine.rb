# frozen_string_literal: true

module Decidim
  module RestFull
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::RestFull

      config.to_prepare do
        Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)
      end

      initializer "rest_full.scopes" do
        Doorkeeper.configure do
          # Define default and optional scopes
          default_scopes :public
          optional_scopes :spaces, :system, :proposals, :meetings, :debates, :pages, :public

          # Enable resource owner password credentials
          grant_flows %w(password client_credentials)

          # Authenticate resource owner
          resource_owner_from_credentials do |_routes|
            # forbid system scope, exclusive to credential flow
            raise ::Doorkeeper::Errors::DoorkeeperError, "can not request system scope with ROPC flow" if (params["scope"] || "").include? "system"

            auth_type = params.require(:auth_type)
            current_organization = request.env["decidim.current_organization"]
            case auth_type
            when "impersonate"
              Decidim::RestFull::ApiClient.find_by(
                uid: params.require("client_id"),
                organization: current_organization
              )
              user = Decidim::User.find_by(
                nickname: params.require("username"),
                organization: current_organization
              )
              user
            when "login"
              Decidim::RestFull::ApiClient.find_by(
                uid: params.require("client_id"),
                organization: current_organization
              )
              user = Decidim::User.find_by(
                nickname: params.require("username"),
                organization: current_organization
              )
              raise ActiveRecord::RecordNotFound, "User not found" unless user.valid_password?(params.require("password"))

              user
            else
              raise Decidim::RestFull::ApiException::BadRequest, "Not allowed param auth_type='#{auth_type}'"
            end
          end
        end
      end
      initializer "rest_full.menu" do
        Decidim::RestFull::Menu.register_system_menu!
      end
    end
  end
end
