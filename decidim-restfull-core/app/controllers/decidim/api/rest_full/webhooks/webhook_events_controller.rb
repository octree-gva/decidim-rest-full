# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Webhooks
        class WebhookEventsController < ApplicationController
          before_action { doorkeeper_authorize! :webhooks }
          before_action :authorize_read!

          def show
            event_type = params.require(:event_type)
            entry = Decidim::RestFull::Core::WebhookEventCatalog.find(event_type)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Webhook event not found" unless entry

            render json: Decidim::RestFull::Core::WebhookEventCatalog.example_payload_for(
              event_type,
              organization: current_organization
            ), status: :ok
          rescue ActiveRecord::RecordNotFound
            raise Decidim::RestFull::Core::ApiException::NotFound, "No sample resource for webhook event"
          end

          private

          def authorize_read!
            authorize! :read, Decidim::RestFull::Core::WebhookRegistration
          end
        end
      end
    end
  end
end
