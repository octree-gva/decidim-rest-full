# frozen_string_literal: true

# Eager require: initializer runs early; app/services is not always autoload-ready when +Extension.register+ runs.
require File.join(
  Decidim::RestFull::Meetings::ENGINE_ROOT,
  "app/services/decidim/rest_full/meetings/upcoming_meeting_webhook_handler.rb"
)

module Decidim
  module RestFull
    module Meetings
      class Engine < ::Rails::Engine
        config.root = Meetings::ENGINE_ROOT

        initializer "rest_full.meetings.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_meetings_api

          Decidim::RestFull::Extension.register(:meetings) do |ext|
            ext.permissions(:meetings, "meetings.read", group: :meetings)
            ext.open_api_definitions(
              File.join(Meetings::ENGINE_ROOT, "lib/decidim/rest_full/meetings/test_definitions.rb")
            )
            ext.rswag_specs(File.join(Meetings::ENGINE_ROOT, "spec/requests/**/*_spec.rb"))
            ext.webhooks(
              Decidim::RestFull::Meetings::UpcomingMeetingWebhookHandler::HANDLED_EVENT,
              handler: Decidim::RestFull::Meetings::UpcomingMeetingWebhookHandler.method(:call)
            )
          end
        end
      end
    end
  end
end
