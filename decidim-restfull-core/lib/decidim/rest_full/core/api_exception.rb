# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
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
          "Decidim::RestFull::Core::ApiException::BadRequest" => { status: 400, message: "Bad request" },
          "Decidim::RestFull::Core::ApiException::Unauthorized" => { status: 401, message: "Unauthorized access" },
          "Decidim::RestFull::Core::ApiException::Forbidden" => { status: 403, message: "Forbidden" },
          "Decidim::RestFull::Core::ApiException::NotFound" => { status: 404, message: "Resource not found" },
          "Decidim::RestFull::Core::ApiException::NotImplemented" => { status: 501, message: "Not implemented" }
        }.freeze

        class BaseError < StandardError; end

        # 400 with optional machine-readable error_details (ActiveModel types).
        class BadRequest < StandardError
          attr_reader :error_details

          def initialize(message = nil, error_details: nil)
            @error_details = error_details
            super(message)
          end

          # Map ActiveModel::Error objects → BadRequest with error_details.
          # Note: ActiveModel::Errors#to_a returns message strings — iterate with #each/#map instead.
          def self.from_errors(errors)
            list = if errors.is_a?(ActiveModel::Errors)
                     errors.map { |error| error }
                   else
                     Array(errors)
                   end
            details = list.map do |error|
              {
                code: code_for(error),
                field: error.attribute.to_s,
                description: error.full_message
              }
            end
            message = details.map { |d| d[:description] }.join(". ")
            new(message, error_details: details)
          end

          # Convenience: form.errors, optionally limited to attribute names.
          def self.from_form(form, only: nil)
            errs = form.errors
            if only
              keys = Array(only).map(&:to_s)
              errs = errs.select { |err| keys.include?(err.attribute.to_s) }
            end
            from_errors(errs)
          end

          # Prefer ActiveModel symbol types. Some hosts (e.g. DecidimAwesome
          # etiquette override) add translated strings instead of symbols.
          def self.code_for(error)
            type = error.respond_to?(:raw_type) ? error.raw_type : error.type
            return type.to_s if type.is_a?(Symbol)

            infer_code_from_message(type.to_s.presence || error.message.to_s)
          end
          private_class_method :code_for

          def self.infer_code_from_message(message)
            msg = message.to_s.downcase
            return "too_much_caps" if msg.include?("capital letter") && msg.include?("too many")
            return "must_start_with_caps" if msg.include?("start with a capital")
            return "too_many_marks" if msg.include?("punctuation")
            return "too_short" if msg.include?("too short")
            return "too_long" if msg.include?("too long")
            return "blank" if msg.include?("blank")
            return "cant_be_equal_to_template" if msg.include?("template")

            "invalid"
          end
          private_class_method :infer_code_from_message
        end

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
                  payload = {
                    error: "#{context[:status]}: #{context[:message]}",
                    error_description: if context[:status] == 400
                                         exception.message
                                       else
                                         Rails.env.test? && ENV.fetch("SWAGGER_DRY_RUN", "1") == "1" ? "#{Rails.env}: #{exception.message}" : (context[:message]).to_s
                                       end
                  }
                  if exception.respond_to?(:error_details) && exception.error_details.present?
                    payload[:error_details] = exception.error_details
                  end
                  render status: context[:status], json: payload.compact
                end
              end
            end
          end
        end
      end
    end
  end
end
