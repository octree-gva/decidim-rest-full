# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        # Builds the outbound webhook envelope from a domain resource + event metadata.
        # Subclasses implement +resource_serializable_hash+ (JSON:API document from existing API serializers).
        class WebhookSerializer
          def initialize(resource, event_name:, organization:, timestamp: nil)
            @resource = resource
            @event_name = event_name.to_s
            @organization = organization
            @timestamp = timestamp || Time.current.to_i
          end

          # Final HTTP POST body: { type, data } where data is the JSON:API resource object.
          def envelope
            document = resource_serializable_hash
            resource_data = document[:data] || document["data"]
            {
              "type" => event_name,
              "data" => resource_data.as_json
            }
          end

          # Sample envelope for catalog registration / GET /webhook_events/{event_type}.
          def self.example_envelope(organization, event_name:)
            resource = find_example_resource(organization, event_name:)
            raise ActiveRecord::RecordNotFound, "No sample resource for #{event_name}" unless resource

            new(resource, event_name:, organization:).envelope
          end

          def self.find_example_resource(_organization, event_name:)
            raise NotImplementedError
          end

          # Attributes for WebhookEventForm / WebhookJob (data is the full JSON:API document).
          def event_attributes
            {
              type: event_name,
              data: resource_serializable_hash,
              timestamp:
            }
          end

          protected

          attr_reader :resource, :event_name, :organization, :timestamp

          def resource_serializable_hash
            raise NotImplementedError
          end

          def serializer_params(extra = {})
            {
              only: [],
              locales: organization.available_locales || Decidim.available_locales,
              host: organization.host,
              act_as: nil
            }.merge(extra)
          end
        end
      end
    end
  end
end
