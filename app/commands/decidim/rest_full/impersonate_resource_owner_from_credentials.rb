# frozen_string_literal: true

module Decidim
  module RestFull
    class ImpersonateResourceOwnerFromCredentials < Decidim::Command
      attr_reader :api_client, :params, :current_organization

      def initialize(api_client, params, current_organization)
        @api_client = api_client
        @params = params
        @current_organization = current_organization
      end

      def call
        ability.authorize! :impersonate, Decidim::RestFull::ApiClient
        validate_params!
        user = user_from_params
        if user
          # Update meta data
          user.update!(
            extended_data: (user.extended_data || {}).merge(
              extra
            )
          )
        else
          # Create user
          user = create_user_from_params!
        end
        broadcast(:ok, user)
        user_from_params
      rescue StandardError => e
        broadcast(:error, e.message)
      end

      private

      def validate_params!
        has_id = params.has_key? :id
        has_username = params.has_key? :username
        wants_register = meta["register_on_missing"]
        user_exists = user_from_params

        return true if user_exists

        # It does not exists, and do not want to register.
        raise StandardError, "User not found. To create one, user meta.register_on_missing" unless wants_register

        # It does not exists, want to register, but has no username
        raise StandardError, "Param .username required. Check your impersonation payload" unless has_username
        # It does not exists, want to register, but already gave an id
        raise StandardError, "Param .id forbidden. Check your impersonation payload" if has_id

        true
      end

      def create_user_from_params!
        email = meta.delete("email") || "#{username}@example.org"
        name = meta.delete("name") || username.titleize

        user = current_organization.users.build(
          email: email,
          name: name,
          nickname: username,
          extended_data: extra
        )
        user.accepted_tos_version = if meta["accept_tos_on_register"]
                                      current_organization.tos_version + 1.hour
                                    else
                                      # Will need to revalidate tos
                                      current_organization.tos_version - 1.hour
                                    end
        user.tos_agreement = true

        password = begin
          special_chars = ["@", "#", "$", "%", "^", "&", "*", "-", "_", "+", "=", "~"]
          part1 = ::Devise.friendly_token.first((20 + 1) / 2)
          special_part = special_chars.sample(2).join
          part2 = ::Devise.friendly_token.first((20 + 1) / 2)

          # Combine parts to form the final password
          password = part1 + special_part + part2
          password.chars.shuffle.join
        end
        user.password = user.password_confirmation = password
        user.skip_confirmation! if meta["skip_confirmation_on_register"]

        raise StandardError, user.errors.full_messages unless user.valid?

        user.save!
        user
      end

      def user_from_params
        @user_from_params ||= if params.has_key? "id"
                                Decidim::User.find_by(
                                  id: params[:id],
                                  organization: current_organization
                                )
                              else
                                Decidim::User.find_by(
                                  nickname: username,
                                  organization: current_organization
                                )
                              end
      end

      def extra
        @extra ||= params[:extra] || {}
      end

      def default_meta
        {
          "register_on_missing" => false,
          "accept_tos_on_register" => false,
          "skip_confirmation_on_register" => false
        }
      end

      def meta
        @meta ||= begin
          user_meta = params[:meta] || {}
          default_meta.merge(user_meta)
        end
      end

      def username
        raise StandardError, "Username params required" unless params[:username]

        @username ||= params[:username]
      end

      def ability
        @ability ||= Decidim::RestFull::Ability.new(api_client)
      end
    end
  end
end
