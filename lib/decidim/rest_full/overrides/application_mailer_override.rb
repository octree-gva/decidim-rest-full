# frozen_string_literal: true

module Decidim
  module RestFull
    module ApplicationMailerOverride
      extend ActiveSupport::Concern

      included do
        # Alias the original mail method
        alias_method :original_decidim_mail, :mail

        ##
        # Avoid to send emails to @example.org.
        # It's a common hack to avoid using emails when
        # using phone number or other.
        def mail_without_example_org(headers = {}, &block)
          to = headers[:to] || nil
          return if !to || to.end_with?("@example.org")

          original_decidim_mail(headers, &block)
        end

        ###
        # Compute email content and fire an active support notification.
        # This will enable to send webhooks with emails content.
        def mail_with_events(headers = {}, &block)
          headers = apply_defaults(headers)
          responses = collect_responses(headers, &block)
          message = responses.find { |resp| resp[:content_type] == "text/html" }
          if message
            publish_notification(
              to: headers[:to],
              subject: headers[:subject],
              body_html: message[:body],
              body_text: Rails::Html::FullSanitizer.new.sanitize(message[:body])
            )
          end
          mail_without_example_org(headers, &block)
        end

        # Override the mail method
        alias_method :mail, :mail_with_events

        private

        def publish_notification(options)
          ActiveSupport::Notifications.publish(
            "decidim.rest.#{self.class.name.demodulize.underscore}_performed",
            to: options[:to],
            subject: options[:subject],
            body_html: options[:body_html],
            body_text: options[:body_text]
          )
        end
      end
    end
  end
end
