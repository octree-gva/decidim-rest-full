# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ApplicationController < ActionController::API
        include Decidim::RestFull::ApiException::Handler
        delegate :can?, :cannot?, :authorize!, to: :ability

        protected

        ##
        # Give the current API actor.
        # if acting as a service (machine-to-machine): Act as you where the first available admin
        # if having a resource owner: as the resource owner
        # else act as you are a public agent
        def act_as
          @act_as ||= if service_token?
                        Decidim::User.where(admin: true, blocked_at: nil, organization: current_organization).where.not(confirmed_at: nil).first
                      elsif current_user
                        current_user
                      end
        end

        def service_token?
          doorkeeper_token.valid? && !doorkeeper_token.resource_owner_id
        end

        def current_user
          Decidim::User.find_by(id: doorkeeper_token.resource_owner_id, organization: current_organization)
        end

        def current_organization
          request.env["decidim.current_organization"]
        end

        def populated_fields(default_fields, allowed_fields)
          fields = populate_params || default_fields
          raise Decidim::RestFull::ApiException::BadRequest, "Not allowed populate param: #{fields.join(", ")}" if allowed_fields.empty?

          unallowed_params = fields.reject { |f| allowed_fields.include?(f) }
          raise Decidim::RestFull::ApiException::BadRequest, "Not allowed populate param: #{unallowed_params.join(", ")}" unless unallowed_params.empty?

          fields.push(:id) unless fields.include? :id
          # Always add timestamping
          fields.push(:created_at) unless fields.include? :created_at
          fields.push(:updated_at) unless fields.include? :updated_at

          fields
        end

        def available_locales
          @available_locales ||= begin
            not_allowed_locales = parsed_locales_params.reject { |l| all_locales.include? l }
            raise Decidim::RestFull::ApiException::BadRequest, "Not allowed locales: #{not_allowed_locales.join}" unless not_allowed_locales.empty?

            parsed_locales_params
          end
        end

        private

        def ability
          @ability ||= Decidim::RestFull::Ability.from_doorkeeper_token(doorkeeper_token)
        end

        def populate_params
          @populate_params ||= if params[:populate].is_a?(String)
                                 params[:populate].split(",").map(&:to_sym)
                               elsif params[:populate].is_a?(Array)
                                 params[:populate].map(&:to_sym)
                               end
        end

        def all_locales
          @all_locales ||= I18n.available_locales.map(&:to_sym)
        end

        def parsed_locales_params
          @parsed_locales_params ||= if params[:locales].is_a?(String)
                                       params[:locales].split(",").map(&:to_sym)
                                     elsif params[:locales].is_a?(Array)
                                       params[:locales].map(&:to_sym)
                                     else
                                       I18n.available_locales.map(&:to_sym)
                                     end
        end
      end
    end
  end
end
