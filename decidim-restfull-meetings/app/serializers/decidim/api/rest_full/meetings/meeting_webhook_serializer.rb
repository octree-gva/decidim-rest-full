# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Meetings
        class MeetingWebhookSerializer < ::Decidim::Api::RestFull::Core::WebhookSerializer
          def self.find_example_resource(organization, event_name:) # rubocop:disable Lint/UnusedMethodArgument
            component_ids = Decidim::Component
                            .where(manifest_name: "meetings")
                            .filter_map { |component| component.id if component.organization == organization }
            Decidim::Meetings::Meeting.where(decidim_component_id: component_ids).order(:id).last
          end

          protected

          def resource_serializable_hash
            MeetingSerializer.new(resource, params: serializer_params(publishable: true)).serializable_hash
          end
        end
      end
    end
  end
end
