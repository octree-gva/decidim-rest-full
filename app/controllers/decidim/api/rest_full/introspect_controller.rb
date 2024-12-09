# frozen_string_literal: true

# app/controllers/api/rest_full/system/organizations_controller.rb
module Decidim
  module Api
    module RestFull
      class IntrospectController < ApplicationController
        # Introspect current token
        def show
          render json: {
            data: {
              sub: subject,
              active: active?,
              token: token_details
            }.merge(user_details)
          }
        end

        private

        def subject
          doorkeeper_token.id
        end

        def active?
          token_valid = doorkeeper_token.valid? && !doorkeeper_token.expired?
          return token_valid unless has_user?

          user_valid = user && !user.blocked? && user.locked_at.blank?
          user_valid && token_valid
        end

        def has_user?
          !doorkeeper_token.resource_owner_id.nil?
        end

        def user
          Decidim::User.find_by(organization: current_organization, id: doorkeeper_token.resource_owner_id)
        end

        def user_details
          return {} unless has_user?

          {
            resource: UserSerializer.new(
              user,
              params: { host: current_organization.host },
              fields: { user: [:email, :name, :id, :created_at, :updated_at, :personal_url, :locale] }
            ).serializable_hash[:data]
          }
        end

        def token_details
          {
            scope: doorkeeper_token.scopes.to_a,
            expires_in: doorkeeper_token.expires_in,
            created_at: doorkeeper_token.created_at
          }
        end
      end
    end
  end
end
