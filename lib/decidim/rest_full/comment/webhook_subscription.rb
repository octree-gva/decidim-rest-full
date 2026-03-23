# frozen_string_literal: true

module Decidim
  module RestFull
    module Comment
      # Maps ActiveSupport::Notifications event names to webhook permission / payload types.
      module WebhookSubscription
        EVENT_NAME_FOR = {
          "decidim.comments.create_comment:after" => "comment_creation.succeeded",
          "decidim.comments.update_comment:after" => "comment_update.succeeded"
        }.freeze

        module_function

        def event_name_for(notification_name)
          EVENT_NAME_FOR[notification_name]
        end
      end
    end
  end
end
