# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module User
        class MeController < ResourcesController
          before_action { doorkeeper_authorize! :oauth }
          before_action { ability.authorize! :login, ::Decidim::User }
          before_action do
            raise Decidim::RestFull::ApiException::BadRequest, "User required" unless current_user
            raise Decidim::RestFull::ApiException::BadRequest, "User blocked" if current_user.blocked_at
            raise Decidim::RestFull::ApiException::BadRequest, "User locked" if current_user.locked_at
          end

          def create_magic_link
            token = current_user.rest_full_generate_magic_token
            render json: Decidim::Api::RestFull::MagicLinkSerializer.new(
              token,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as
              }
            ).serializable_hash, status: :created
          end

          def signin_magic_link
            token = params.require(:magic_token)
            magic_token = Decidim::RestFull::MagicToken.find_by(magic_token: token)
            raise Decidim::RestFull::ApiException::BadRequest, "Token not found" unless magic_token
            raise Decidim::RestFull::ApiException::BadRequest, "Invalid Token" unless magic_token.valid_token?

            user = magic_token.user
            scope = user.admin? ? :admin : :user
            sign_in magic_token.user, scope: scope unless user_signed_in?
            endpoint_body = Decidim::Api::RestFull::MagicLinkRedirectSerializer.new(
              magic_token,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as
              }
            ).serializable_hash
            redirect_to ::Decidim::Core::Engine.routes.url_helpers.root_path
            response.body = endpoint_body.to_json
          end

          protected

          def model_class
            ::Decidim::User
          end

          def collection
            model_class.where(organization: current_organization, blocked_at: nil, locked_at: nil)
          end
        end
      end
    end
  end
end
