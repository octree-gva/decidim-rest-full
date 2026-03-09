# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      # Base for all REST API controllers. Handles API exceptions and provides
      # helpers for OAuth (current_user, act_as, service_token?), visibility
      # (visible_spaces, in_visible_spaces), and space_class_from_name.
      class ApplicationController < ActionController::API
        include Decidim::RestFull::ApiException::Handler
        delegate :can?, :cannot?, :authorize!, to: :ability

        protected

        def space_class_from_name(manifest_name)
          Decidim.participatory_space_registry.manifests.find do |manifest|
            manifest.name == :"#{manifest_name}"
          end.model_class_name
        end

        ##
        # Find components that are published in a visible space.
        # exemple: if the user has no view on Decidim::Assembly#2
        #          THEN should not be able to query any Decidim::Assembly#2 components
        def in_visible_spaces(context = Decidim::Component.all)
          if visible_spaces.size.positive?
            first_visible_space = visible_spaces.first
            query_manifest = context
            query = query_manifest.where(**first_visible_space)
            visible_spaces[1..].each do |visible_space|
              query = query.or(query_manifest.where(**visible_space))
            end
            query
          else
            context.where("1=0")
          end
        end

        ##
        # All the spaces (assembly, participatory process) visible
        # for the current actor.
        # @returns participatory_space_type, participatory_space_id values
        def visible_spaces
          @visible_spaces ||= begin
            spaces = Decidim.participatory_space_registry.manifests.map do |space|
              model = space.model_class_name
              query = model.constantize.visible_for(act_as).where(organization: current_organization)
              {
                participatory_space_type: model,
                participatory_space_id: query.ids
              }
            end
            spaces.reject do |space_params|
              space_params[:participatory_space_id].empty?
            end
          end
        end

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

        def client_id
          doorkeeper_token.application_id
        end

        def service_token?
          doorkeeper_token.valid? && !doorkeeper_token.resource_owner_id
        end

        def current_user
          Decidim::User.find_by(id: doorkeeper_token.resource_owner_id, organization: current_organization)
        end

        def current_organization
          @current_organization ||= request.env["decidim.current_organization"]
        end

        def current_locale
          @current_locale ||= if current_user
                                current_user.locale || current_organization.default_locale
                              else
                                current_organization.default_locale
                              end
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
            raise Decidim::RestFull::ApiException::BadRequest, "Not allowed locales: #{not_allowed_locales.join(", ")}" unless not_allowed_locales.empty?

            parsed_locales_params
          end
        end

        private

        def authorization_token
          @authorization_token ||= begin
            header = request.headers["Authorization"] || request.authorization
            header.to_s.split.last if header.present?
          end
        end

        def doorkeeper_token
          return @doorkeeper_token if defined?(@doorkeeper_token)

          @doorkeeper_token = authorization_token && ::Doorkeeper::AccessToken.by_token(authorization_token)
        end

        def doorkeeper_authorize!(*required_scopes)
          token = doorkeeper_token
          unless token&.accessible?
            auth_env = request.headers.env.select { |k, _| k.to_s.include?("AUTH") }
            debug = {
              header_token: authorization_token,
              auth_env:,
              token_found: !token.nil?,
              token_scopes: (token&.scopes || []).to_a,
              token_revoked_at: token&.revoked_at,
              token_expires_in: token&.expires_in,
              token_created_at: token&.created_at
            }.inspect
            raise Decidim::RestFull::ApiException::Unauthorized, "The access token is invalid (debug: #{debug})"
          end

          missing_scopes = required_scopes.map(&:to_s) - token.scopes.to_a
          raise Decidim::RestFull::ApiException::Forbidden, "Missing required scopes: #{missing_scopes.join(", ")}" if missing_scopes.any?

          token
        end

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
