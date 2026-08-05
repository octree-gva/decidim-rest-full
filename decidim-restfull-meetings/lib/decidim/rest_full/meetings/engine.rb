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

        config.to_prepare do
          next unless defined?(Decidim::Meetings::Meeting)

          Decidim::Meetings::Meeting.include(Decidim::RestFull::Core::HasExtendedData)
        end

        initializer "rest_full.meetings.extension" do
          Decidim::RestFull::Extension.register(:meetings) do |ext|
            ext.toggle_feature gem: "decidim-restfull-meetings"
            ext.controller_paths "meetings"
            ext.oauth_scopes :meetings
            ext.permissions(:meetings, "meetings.read", group: :meetings)
            ext.permissions(:meetings, "meetings.extended_data.read", group: :meetings)
            ext.permissions(:meetings, "meetings.extended_data.update", group: :meetings)
            ext.open_api_definitions(
              File.join(Meetings::ENGINE_ROOT, "lib/decidim/rest_full/meetings/test_definitions.rb")
            )
            ext.rswag_specs(File.join(Meetings::ENGINE_ROOT, "spec/requests/**/*_spec.rb"))
            ext.webhook_event(
              "meetings.upcoming_reminder.succeeded",
              scope: :meetings,
              payload_schema_ref: nil,
              schema_key: :wh_meeting_upcoming,
              trigger: "Upcoming meeting reminder",
              example: lambda { |organization|
                ::Decidim::Api::RestFull::Meetings::MeetingWebhookSerializer.example_envelope(
                  organization,
                  event_name: "meetings.upcoming_reminder.succeeded"
                )
              }
            )
            ext.webhooks(
              Decidim::RestFull::Meetings::UpcomingMeetingWebhookHandler::HANDLED_EVENT,
              handler: Decidim::RestFull::Meetings::UpcomingMeetingWebhookHandler.method(:call)
            )
            ext.routes do
              Decidim::RestFull::Routing.read_resources(
                self,
                :meetings,
                controller: "meetings/meetings",
                only: [:index, :show]
              ) do
                member do
                  resources :extended_data, only: [], controller: "/decidim/api/rest_full/meetings/meeting_extended_data" do
                    collection do
                      get "/", action: :index
                      put "/", action: :update
                      put "/sync", action: :update_sync
                    end
                  end
                end
              end
            end
          end

          Decidim::RestFull::Core::Configuration.events_for_meetings = %w(
            meetings.upcoming_reminder.succeeded
          )
        end
      end
    end
  end
end

