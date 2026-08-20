# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        class OrganizationWebhookSerializer < WebhookSerializer
          def self.find_example_resource(organization, event_name:) # rubocop:disable Lint/UnusedMethodArgument
            organization
          end

          protected

          def resource_serializable_hash
            OrganizationSerializer.new(resource, params: serializer_params(includes_extended: false)).serializable_hash
          end
        end
      end
    end
  end
end
