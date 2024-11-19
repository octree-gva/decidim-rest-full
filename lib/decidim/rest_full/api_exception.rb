# frozen_string_literal: true

module Decidim
  module RestFull
    module ApiException
      EXCEPTIONS = {
        # Unknown error
        "StandardError" => { status: 500, message: "An error occurred" },
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

        # Generic Application-Level Errors
        "BadRequest" => { status: 400, message: "Bad request" },
        "Unauthorized" => { status: 401, message: "Unauthorized access" },
        "Forbidden" => { status: 403, message: "Forbidden" },
        "NotFound" => { status: 404, message: "Resource not found" }
      }.freeze

      class BaseError < StandardError; end

      module Handler
        def self.included(klass)
          klass.class_eval do
            EXCEPTIONS.each do |exception_name, context|
              rescue_from_name = if ApiException.const_defined?(exception_name)
                                   exception_name
                                 else
                                   ApiException.const_set(exception_name, Class.new(BaseError))
                                   "Decidim::RestFull::ApiException::#{exception_name}"
                                 end

              rescue_from rescue_from_name.to_s do |exception|
                render status: context[:status],
                       json: {
                         error_code: context[:status],
                         message: context[:message],
                         detail: Rails.env.production? ? nil : exception.message
                       }.compact
              end
            end
          end
        end
      end
    end
  end
end
