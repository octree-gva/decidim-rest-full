# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ApplicationController < ActionController::API
        include Decidim::RestFull::ApiException::Handler

        protected

        def populated_fields(default_fields, allowed_fields)
          fields = populate_params || default_fields
          raise Decidim::RestFull::ApiException::BadRequest, "Not allowed populate param: #{fields.join(", ")}" if allowed_fields.empty?

          fields.push(:id) unless fields.include? :id
          # Always add timestamping
          fields.push(:created_at) unless fields.include? :created_at
          fields.push(:updated_at) unless fields.include? :updated_at

          unallowed_params = fields.reject { |f| allowed_fields.include?(f) }
          raise Decidim::RestFull::ApiException::BadRequest, "Not allowed populate param: #{unallowed_params.join(", ")}" unless unallowed_params.empty?

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
