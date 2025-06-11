# frozen_string_literal: true

module Decidim
  module RestFull
    class WebhookRegistration < ApplicationRecord
      self.table_name = "webhooks_tables"
      belongs_to :api_client, class_name: "Decidim::RestFull::ApiClient"

      validates :url, presence: true
      validates :subscriptions, presence: true

      before_validation :generate_private_key

      def send_webhook(event, timestamp)
        json_payload = {
          event: event["type"],
          # The event data is the result of the serializer,
          # that contains a data key as well.
          data: event["data"]["data"],
          alg: "HS256"
        }.to_json
        signature = sign_payload(json_payload, timestamp)

        headers = {
          "Content-Type" => "application/json",
          "X-Webhook-Signature" => signature,
          "X-Webhook-Timestamp" => timestamp
        }
        uri = URI(url)
        request = Net::HTTP::Post.new(uri, headers)
        request.body = json_payload
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        # Raise an error if Status code is not >200 <300
        # This will trigger a retry in active job mecanisms
        # @see jobs/decidim/rest_full/webhook_job.rb
        raise WebhookFailedError unless response.code.to_i.between?(200, 300)

        response.body
      end

      private

      ##
      # Sign the <timestamp>.<json_payload> with the private key
      # This prevent replay attacks
      def sign_payload(json_payload, timestamp)
        data = "#{timestamp}.#{json_payload}"
        OpenSSL::HMAC.hexdigest("SHA256", private_key, data)
      end

      def generate_private_key
        return if private_key.present? && private_key.length == 64

        self.private_key = SecureRandom.hex(32)
      end
    end
  end
end
