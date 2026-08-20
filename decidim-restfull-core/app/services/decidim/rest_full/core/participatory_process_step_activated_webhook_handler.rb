# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Dispatches when Decidim publishes +decidim.events.participatory_process.step_activated+.
      module ParticipatoryProcessStepActivatedWebhookHandler
        HANDLED_EVENT = "decidim.events.participatory_process.step_activated"
        WEBHOOK_EVENT = "participatory_process.step_activated.succeeded"

        def self.call(event_name, data)
          return unless event_name == HANDLED_EVENT

          payload = normalize_payload(data)
          step = payload[:resource]
          return unless step.is_a?(::Decidim::ParticipatoryProcessStep)

          process = step.participatory_process
          organization = process.organization

          SpaceWebhookJob.perform_later(WEBHOOK_EVENT, process.id, organization.id, step.id)
        end

        def self.normalize_payload(data)
          case data
          when Hash
            data.symbolize_keys
          when ActiveSupport::Notifications::Event
            data.payload.symbolize_keys
          else
            {}
          end
        end

        private_class_method :normalize_payload
      end
    end
  end
end
