# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module System
        class UsersController < ApplicationController
          before_action do
            doorkeeper_authorize! :system
            authorize! :read, ::Decidim::User
          end

          # List all users
          def index
            # Fetch users and paginate
            users = paginate(Decidim::User.where(organization: current_organization).ransack(params[:filter]).result)
            # Render the response
            render json: UserSerializer.new(
              users,
              params: { host: current_organization.host }
            ).serializable_hash
          end
        end
      end
    end
  end
end
