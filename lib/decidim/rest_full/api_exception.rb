# frozen_string_literal: true

module Decidim
  module RestFull
    # API exception types and HTTP status mapping.
    # Handler is included in Doorkeeper::TokensController and adds rescue_from for each
    # EXCEPTIONS entry so API errors return consistent JSON (error + error_description).
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
        "Doorkeeper::Errors::InvalidToken" => { status: 401, message: "Unauthorized access" },
        "Doorkeeper::Errors::InvalidTokenStrategy" => { status: 400, message: "Bad request" },

        # Generic Application-Level Errors
        "Decidim::RestFull::ApiException::BadRequest" => { status: 400, message: "Bad request" },
        "Decidim::RestFull::ApiException::Unauthorized" => { status: 401, message: "Unauthorized access" },
        "Decidim::RestFull::ApiException::Forbidden" => { status: 403, message: "Forbidden" },
        "Decidim::RestFull::ApiException::NotFound" => { status: 404, message: "Resource not found" }
      }.freeze

      class BaseError < StandardError; end

      class BadRequest < StandardError; end

      class NotImplemented < StandardError; end

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
                       error_description: if Rails.env.test? && ENV.fetch("SWAGGER_DRY_RUN",
                                                                          "1") == "1"
                                            "Internal Server Error (#{Rails.env}: #{exception.message || "unknown"})"
                                          else
                                            "Internal Server Error"
                                          end
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
                                              Rails.env.test? && ENV.fetch("SWAGGER_DRY_RUN", "1") == "1" ? "#{Rails.env}: #{exception.message}" : (context[:message]).to_s
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
