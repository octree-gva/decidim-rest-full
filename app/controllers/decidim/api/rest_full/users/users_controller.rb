# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Users
        class UsersController < ApplicationController
          before_action do
            doorkeeper_authorize! :oauth
            authorize! :read, ::Decidim::User
          end
          before_action :validates_filter_params!
          # List all users
          def index
            Decidim::User.ransacker :id do |_r|
              Arel.sql('CAST("decidim_users"."id" AS VARCHAR)')
            end
            # Fetch users and paginate
            users = paginate(Decidim::User.where(organization: current_organization).ransack(params[:filter]).result)
            # Render the response
            render json: UserSerializer.new(
              users,
              params: { host: current_organization.host, includes_extended: can_include_extended? }
            ).serializable_hash
          end

          private

          def validates_filter_params!
            return unless params[:filter]

            authorize! :read_extended_data, ::Decidim::User if params[:filter].keys.any? { |param_k| param_k.starts_with?("extended_data") }
          end

          def can_include_extended?
            can? :read_extended_data, ::Decidim::User
          end
        end
      end
    end
  end
end
