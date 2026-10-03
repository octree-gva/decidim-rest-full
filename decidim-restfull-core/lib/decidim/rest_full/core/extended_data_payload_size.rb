# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Shared size gate for sync extended_data writes (REST + ROPC extra).
      module ExtendedDataPayloadSize
        module_function

        def assert!(data)
          max = Decidim::RestFull.config.max_extended_data_payload_bytes
          return if max.blank? || !max.positive?

          size = data.to_json.bytesize
          return if size <= max

          raise ApiException::BadRequest,
                "extended_data exceeds maximum size of #{max} bytes"
        end
      end
    end
  end
end
