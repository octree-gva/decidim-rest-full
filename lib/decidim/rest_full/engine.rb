# frozen_string_literal: true

module Decidim
  module RestFull
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::RestFull

      config.to_prepare do
        Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)
        Decidim::User.include(Decidim::RestFull::UserExtendedDataRansack)
        ::Doorkeeper::TokensController.include(Decidim::RestFull::ApiException::Handler)
      end

      initializer "rest_full.scopes" do
        Doorkeeper.configure do
          handle_auth_errors :raise
          # Define default and optional scopes
          default_scopes :public
          optional_scopes :spaces, :system, :proposals, :meetings, :debates, :pages, :public, :blogs
          # Enable resource owner password credentials
          grant_flows %w(password client_credentials)
          custom_introspection_response do |token, _context|
            current_organization = token.application.organization
            user = (Decidim::User.find(token.resource_owner_id) if token.resource_owner_id)
            user_details = if user
                             {
                               resource: Decidim::Api::RestFull::UserSerializer.new(
                                 user,
                                 params: { host: current_organization.host },
                                 fields: { user: [:email, :name, :id, :created_at, :updated_at, :personal_url, :locale] }
                               ).serializable_hash[:data]
                             }
                           else
                             {}
                           end
            token_valid = token.valid? && !token.expired?
            active = if user
                       user_valid = !user.blocked? && user.locked_at.blank?
                       token_valid && user_valid
                     else
                       token_valid
                     end

            {
              sub: token.id,
              # Current organization
              aud: "https://#{current_organization.host}",
              active: active
            }.merge(user_details)
          end
          # Authenticate resource owner
          resource_owner_from_credentials do |_routes|
            # forbid system scope, exclusive to credential flow
            raise ::Decidim::RestFull::ApiException::BadRequest, "can not request system scope with ROPC flow" if (params["scope"] || "").include? "system"

            auth_type = params.require(:auth_type)
            current_organization = request.env["decidim.current_organization"]
            raise ::Decidim::RestFull::ApiException::BadRequest, "Invalid Organization. Check requested host." unless current_organization

            client_id = params.require("client_id")
            raise ::Decidim::RestFull::ApiException::BadRequest, "Invalid Api Client, check client_id credentials" if client_id.size < 8

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

              command_result = ImpersonateResourceOwnerFromCredentials.call(
                api_client,
                impersonation_payload,
                current_organization
              ) do
                on(:ok) do |user|
                  user
                end
                on(:error) do |error_message|
                  raise ::Decidim::RestFull::ApiException::BadRequest, error_message
                end
              end

              command_result[:ok]
            when "login"
              ability.authorize! :login, Decidim::RestFull::ApiClient
              user = Decidim::User.find_by(
                nickname: params.require("username"),
                organization: current_organization
              )
              raise ::Decidim::RestFull::ApiException::BadRequest, "User not found" unless user.valid_password?(params.require("password"))

              user
            else
              raise ::Decidim::RestFull::ApiException::Unauthorized, "Not allowed param auth_type='#{auth_type}'"
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
