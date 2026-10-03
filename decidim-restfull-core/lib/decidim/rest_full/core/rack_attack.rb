# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Registers a Rack::Attack throttle for ROPC register-on-missing.
      module RackAttack
        THROTTLE_NAME = "decidim/rest_full/oauth_register"
        PAYLOAD_ENV_KEY = "decidim.rest_full.oauth_register_payload"

        module_function

        def install!
          return unless defined?(::Rack::Attack)

          limit = Decidim::RestFull.config.register_per_minute
          return if limit.blank? || limit.to_i <= 0

          ::Rack::Attack.throttle(THROTTLE_NAME, limit: limit.to_i, period: 1.minute) do |req|
            discriminator_for(req)
          end
        end

        def discriminator_for(req)
          return unless register_ropc_request?(req)

          org = req.env["decidim.current_organization"]
          host = org&.host || req.host.to_s
          client_id = register_payload(req)["client_id"].to_s
          return if client_id.blank?

          "#{host}:#{client_id}"
        end

        def register_ropc_request?(req)
          return false unless req.post?
          return false unless req.path.to_s.end_with?("/oauth/token")

          payload = register_payload(req)
          return false unless payload["auth_type"].to_s == "impersonate"

          cast_bool(meta_value(payload, "register_on_missing"))
        end

        def register_payload(req)
          req.env[PAYLOAD_ENV_KEY] ||= parse_request_payload(req)
        end

        def parse_request_payload(req)
          content_type = req.content_type.to_s
          if content_type.include?("application/json")
            body = req.body.read
            req.body.rewind if req.body.respond_to?(:rewind)
            return {} if body.blank?

            JSON.parse(body)
          else
            req.params.to_h
          end
        rescue JSON::ParserError, TypeError
          {}
        end

        def meta_value(payload, key)
          meta = payload["meta"] || payload[:meta] || {}
          meta[key] || meta[key.to_sym]
        end

        def cast_bool(value)
          ActiveModel::Type::Boolean.new.cast(value)
        end
      end
    end
  end
end
