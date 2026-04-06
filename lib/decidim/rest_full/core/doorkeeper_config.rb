# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Holds Doorkeeper configuration logic so the engine initializer stays short.
      # Used by the rest_full.scopes initializer: introspection response and ROPC
      # (resource owner password credentials) resolution.
      module DoorkeeperConfig
        class << self
          # Build the hash returned by the token introspection endpoint (RFC 7662).
          # Includes sub, aud, active, and optional user resource when token has a resource_owner.
          def introspection_response(token)
            current_organization = token.application.organization
            user = Decidim::User.find_by(id: token.resource_owner_id) if token.resource_owner_id
            user_details = user ? serialized_user_details(user, current_organization) : {}
            token_valid = token.valid? && !token.expired?
            active = token_active?(token_valid, user)

            {
              sub: token.id,
              aud: "https://#{current_organization.host}",
              active:
            }.merge(user_details)
          end

          # Resolve the resource owner (User) for ROPC grant. params and request are the
          # Doorkeeper token request params and the Rails request. Returns a User or raises
          # ApiException::BadRequest / ApiException::Unauthorized.
          def resource_owner_from_credentials(params:, request:)
            raise ::Decidim::RestFull::Core::ApiException::BadRequest, "can not request system scope with ROPC flow" if (params["scope"] || "").include?("system")

            current_organization = request.env["decidim.current_organization"]
            raise ::Decidim::RestFull::Core::ApiException::BadRequest, "Invalid Organization. Check requested host." unless current_organization

            client_id = params.require("client_id")
            raise ::Decidim::RestFull::Core::ApiException::BadRequest, "Invalid Api Client, check client_id credentials" if client_id.size < 8

            api_client = ::Decidim::RestFull::Core::ApiClient.find_by(uid: client_id, organization: current_organization)
            raise ::Decidim::RestFull::Core::ApiException::BadRequest, "Invalid Api Client, check credentials" unless api_client

            auth_type = params.require(:auth_type)
            case auth_type
            when "impersonate"
              find_user_via_impersonate(api_client, params, current_organization)
            when "login"
              find_user_via_login(api_client, params, current_organization)
            else
              raise ::Decidim::RestFull::Core::ApiException::Unauthorized, "Not allowed param auth_type='#{auth_type}'"
            end
          end

          private

          def serialized_user_details(user, current_organization)
            {
              resource: Decidim::Api::RestFull::Core::UserSerializer.new(
                user,
                params: { host: current_organization.host },
                fields: { user: [:email, :name, :id, :created_at, :updated_at, :personal_url, :locale] }
              ).serializable_hash[:data]
            }
          end

          def token_active?(token_valid, user)
            if user
              user_valid = !user.blocked? && user.locked_at.blank?
              token_valid && user_valid
            else
              token_valid
            end
          end

          def find_user_via_impersonate(api_client, params, current_organization)
            impersonation_payload = params.permit(
              :username, :id,
              meta: [:register_on_missing, :accept_tos_on_register, :skip_confirmation_on_register, :send_welcome_message, :name, :email]
            ).to_h

            user = nil
            ::Decidim::RestFull::Core::ImpersonateResourceOwnerFromCredentials.call(
              api_client,
              impersonation_payload,
              current_organization
            ) do
              on(:ok) { |u| user = u }
              on(:error) { |msg| raise ::Decidim::RestFull::Core::ApiException::BadRequest, msg }
            end
            user
          end

          def find_user_via_login(api_client, params, current_organization)
            ability = ::Decidim::RestFull::Core::Ability.new(api_client)
            ability.authorize! :login, ::Decidim::RestFull::Core::ApiClient

            user = Decidim::User.find_by(nickname: params.require("username"), organization: current_organization)
            raise ::Decidim::RestFull::Core::ApiException::BadRequest, "User not found" unless user&.valid_password?(params.require("password"))

            user
          end
        end
      end
    end
  end
end
