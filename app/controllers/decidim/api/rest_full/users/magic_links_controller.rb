# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Users
        # Exposes passwordless magic-link endpoints backed by
        # Decidim::RestFull::Core::MagicToken (model) and migration
        # db/migrate/20250131155931_add_users_magic_token.rb.
        class MagicLinksController < Decidim::Api::RestFull::Core::ResourcesController
          include ::Devise::Controllers::Helpers
          before_action only: [:create] do
            doorkeeper_authorize! :oauth
            ability.authorize! :magic_link, ::Decidim::User
            require_user!
          end
          def show
            token = params.require(:id)
            magic_token = Decidim::RestFull::Core::MagicToken.find_by(magic_token: token)
            raise Decidim::RestFull::Core::ApiException::BadRequest, "Token not found" unless magic_token
            raise Decidim::RestFull::Core::ApiException::BadRequest, "Invalid Token" unless magic_token.valid_token?

            user = magic_token.user
            require_user!(user)

            scope = user.admin? ? :admin : :user
            sign_in(user, scope:)
            destination = magic_token.redirect_url.presence
            if destination
              redirect_to destination, allow_other_host: true
            else
              redirect_to "/"
            end
          end

          def create
            form = Decidim::RestFull::Core::MagicLinkRedirectUrlForm.new(
              redirect_url: params.dig(:data, :redirect_url),
              organization: current_organization
            )
            unless form.valid?
              render json: magic_link_redirect_validation_errors(form), status: :unprocessable_entity
              return
            end

            token = current_user.rest_full_generate_magic_token(redirect_url: form.normalized_redirect_url)
            render json: Decidim::Api::RestFull::Core::MagicLinkSerializer.new(
              token,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as:
              }
            ).serializable_hash, status: :created
          end

          protected

          def magic_link_redirect_validation_errors(form)
            {
              errors: form.errors.map { |error| { attribute: error.attribute.to_s, message: error.message } }
            }
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
