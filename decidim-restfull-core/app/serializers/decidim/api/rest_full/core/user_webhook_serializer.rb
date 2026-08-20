# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        class UserWebhookSerializer < WebhookSerializer
          def self.find_example_resource(organization, event_name:) # rubocop:disable Lint/UnusedMethodArgument
            organization.users.order(:id).last
          end

          protected

          def resource_serializable_hash
            UserSerializer.new(resource, params: serializer_params(includes_extended: false)).serializable_hash
          end
        end
      end
    end
  end
end
