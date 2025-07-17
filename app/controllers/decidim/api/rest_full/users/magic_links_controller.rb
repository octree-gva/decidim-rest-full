# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Users
        class MagicLinksController < ResourcesController
          include ::Devise::Controllers::Helpers
          before_action :check_feature
          before_action only: [:create] do
            doorkeeper_authorize! :oauth
            ability.authorize! :magic_link, ::Decidim::User
            raise Decidim::RestFull::ApiException::BadRequest, "User required" unless current_user
            raise Decidim::RestFull::ApiException::BadRequest, "User blocked" if current_user.blocked_at
            raise Decidim::RestFull::ApiException::BadRequest, "User locked" if current_user.locked_at
          end
          def show
            token = params.require(:id)
            magic_token = Decidim::RestFull::MagicToken.find_by(magic_token: token)
            raise Decidim::RestFull::ApiException::BadRequest, "Token not found" unless magic_token
            raise Decidim::RestFull::ApiException::BadRequest, "Invalid Token" unless magic_token.valid_token?

            user = magic_token.user
            raise Decidim::RestFull::ApiException::BadRequest, "User blocked" if user.blocked_at
            raise Decidim::RestFull::ApiException::BadRequest, "User locked" if user.locked_at

            scope = user.admin? ? :admin : :user
            sign_in_and_redirect user, scope: scope
          end

          def create
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

          protected

          def check_feature
            raise AbstractController::ActionNotFound unless Decidim::RestFull.feature.magic_link?
          end

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
