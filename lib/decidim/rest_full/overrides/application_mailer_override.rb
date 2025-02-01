# frozen_string_literal: true

module Decidim
  module RestFull
    module ApplicationMailerOverride
      extend ActiveSupport::Concern

      included do
        # Alias the original mail method
        alias_method :decidim_original_mail, :mail

        # Override the mail method to add custom behavior
        def mail(headers = {}, &block)
          mail_object = decidim_original_mail(headers, &block)

          return mail_object unless headers[:to]

          # Extract plain text body
          plain_text_body = if mail_object.text_part
                              mail_object.text_part.body.to_s
                            else
                              html_content = mail_object.html_part&.body&.to_s || mail_object.body.to_s
                              Rails::Html::FullSanitizer.new.sanitize(html_content)
                            end

          # Publish notification
          publish_notification(
            to: headers[:to],
            subject: headers[:subject],
            body_text: plain_text_body
          )
          mail_object.perform_deliveries = false if headers[:to].end_with?("example.org")
          mail_object
        end

        private

        # Publish an ActiveSupport notification
        def publish_notification(options)
          ActiveSupport::Notifications.publish(
            "decidim.rest.#{self.class.name.demodulize.underscore}_performed",
            to: options[:to],
            subject: options[:subject],
            body_text: options[:body_text]
          )
        end
      end
    end
  end
end
