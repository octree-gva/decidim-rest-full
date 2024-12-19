# frozen_string_literal: true

module Decidim
  module RestFull
    module ApiException
      EXCEPTIONS = {

        # ActiveRecord Exceptions
        "ActiveRecord::RecordInvalid" => { status: 400, message: "Invalid request" },
        "ActiveRecord::RecordNotSaved" => { status: 400, message: "Record could not be saved" },
        "ActiveRecord::RecordNotFound" => { status: 404, message: "Record not found" },

        # ActionController Exceptions
        "ActionController::ParameterMissing" => { status: 400, message: "Required parameter missing" },
        "ActionController::RoutingError" => { status: 404, message: "Route not found" },
        "AbstractController::ActionNotFound" => { status: 404, message: "Action not found" },
        "ActionController::InvalidAuthenticityToken" => { status: 403, message: "Invalid authenticity token" },
        "ActionController::InvalidCrossOriginRequest" => { status: 403, message: "Invalid cross-origin request" },

        # Parsing Errors
        "ActionDispatch::Http::Parameters::ParseError" => { status: 400, message: "Malformed JSON request" },

        # Authorization errors
        "CanCan::AccessDenied" => { status: 403, message: "Forbidden" },
        "Doorkeeper::Errors::TokenForbidden" => { status: 403, message: "Forbidden" },
        "Doorkeeper::Errors::TokenRevoked" => { status: 403, message: "Forbidden" },
        "Doorkeeper::Errors::TokenExpired" => { status: 403, message: "Forbidden" },

        # Generic Application-Level Errors
        "Decidim::RestFull::ApiException::BadRequest" => { status: 400, message: "Bad request" },
        "Decidim::RestFull::ApiException::Unauthorized" => { status: 401, message: "Unauthorized access" },
        "Decidim::RestFull::ApiException::Forbidden" => { status: 403, message: "Forbidden" },
        "Decidim::RestFull::ApiException::NotFound" => { status: 404, message: "Resource not found" }
      }.freeze

      class BaseError < StandardError; end

      class BadRequest < StandardError; end

      class Unauthorized < StandardError; end

      class Forbidden < StandardError; end

      class NotFound < StandardError; end

      module Handler
        def self.included(klass)
          klass.class_eval do
            rescue_from StandardError do |exception|
              render status: :internal_server_error,
                     json: {
                       error: "Server error",
                       error_description: Rails.env.test? ? "#{Rails.env}: #{exception.class.name} #{exception.message}" : nil
                     }.compact
            end

            EXCEPTIONS.each do |exception_name, context|
              rescue_from exception_name do |exception|
                render status: context[:status],
                       json: {
                         error: "#{context[:status]}: #{context[:message]}",
                         error_description: if context[:status] == 400
                                              exception.message
                                            else
                                              Rails.env.test? ? "#{Rails.env}: #{exception.message}" : nil
                                            end
                       }.compact
              end
            end
          end
        end
      end
    end
  end
end
