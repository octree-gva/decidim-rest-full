# frozen_string_literal: true

module Decidim
  module RestFull
    module Roles
      # Encode/decode a role's composite id from (resource_type, resource_id, user_id, invited_at, type).
      # Id is base64url(JSON) so it is reversible and URL-safe.
      class RoleIdCodec
        PAYLOAD_KEYS = %w(resource_type resource_id user_id invited_at type).freeze

        class << self
          def encode(resource_type:, resource_id:, user_id:, invited_at:, type:)
            payload = {
              "resource_type" => resource_type.to_s,
              "resource_id" => resource_id.to_i,
              "user_id" => user_id.nil? ? nil : user_id.to_i,
              "invited_at" => normalize_invited_at(invited_at),
              "type" => type.to_s
            }
            Base64.urlsafe_encode64(JSON.generate(payload), padding: false)
          end

          def decode(id)
            raw = Base64.urlsafe_decode64(id.to_s)
            h = JSON.parse(raw).slice(*PAYLOAD_KEYS)
            {
              resource_type: h["resource_type"],
              resource_id: h["resource_id"].to_i,
              user_id: h["user_id"].nil? ? nil : h["user_id"].to_i,
              invited_at: h["invited_at"],
              type: h["type"]
            }
          rescue ArgumentError, JSON::ParserError
            nil
          end

          def normalize_invited_at(value)
            return nil if value.blank?
            return value.iso8601 if value.respond_to?(:iso8601)
            return value.to_s if value.is_a?(String) && value.present?

            nil
          end
        end
      end
    end
  end
end
