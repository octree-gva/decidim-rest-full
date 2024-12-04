# frozen_string_literal: true

module Decidim
  module RestFull
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::RestFull

      config.to_prepare do
        Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)
        Decidim::User.include(Decidim::RestFull::UserExtendedDataRansack)
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
            raise ::Doorkeeper::Errors::DoorkeeperError, "Invalid Organization. Check requested host." unless current_organization

            client_id = params.require("client_id")
            raise ::Doorkeeper::Errors::DoorkeeperError, "Invalid Api Client, check client_id credentials" if client_id.size < 8

            api_client = Decidim::RestFull::ApiClient.find_by(
              uid: client_id,
              organization: current_organization
            )
            raise ::Doorkeeper::Errors::DoorkeeperError, "Invalid Api Client, check credentials" unless api_client

            ability = Decidim::RestFull::Ability.new(api_client)
            case auth_type
            when "impersonate"
              impersonation_payload = params.permit(
                :username,
                :id,
                meta: [:register_on_missing, :accept_tos_on_register, :skip_confirmation_on_register, :name, :email]
              ).to_h
              impersonation_payload.merge!({ extra: params[:extra].permit!.to_h }) if params.has_key? :extra

              command_result = ImpersonateResourceOwnerFromCredentials.call(
                api_client,
                impersonation_payload,
                current_organization
              ) do
                on(:ok) do |user|
                  user
                end
                on(:error) do |error_message|
                  raise ::Doorkeeper::Errors::DoorkeeperError, error_message
                end
              end

              command_result[:ok]
            when "login"
              ability.authorize! :login, Decidim::RestFull::ApiClient
              user = Decidim::User.find_by(
                nickname: params.require("username"),
                organization: current_organization
              )
              raise ::Doorkeeper::Errors::DoorkeeperError, "User not found" unless user.valid_password?(params.require("password"))

              user
            else
              raise ::Doorkeeper::Errors::DoorkeeperError, "Not allowed param auth_type='#{auth_type}'"
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
