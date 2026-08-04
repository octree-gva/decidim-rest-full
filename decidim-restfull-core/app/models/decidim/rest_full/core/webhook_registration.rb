# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class WebhookRegistration < ApplicationRecord
        self.table_name = "webhooks_tables"
        belongs_to :api_client, class_name: "Decidim::RestFull::Core::ApiClient"

        validates :url, presence: true
        validates :subscriptions, presence: true

        before_validation :generate_private_key

        def send_webhook(event, timestamp)
          # Serializer hash is JSON:API-shaped ({ "data" => resource }); unwrap for the envelope.
          json_payload = {
            type: event["type"],
            data: event["data"]["data"]
          }.to_json
          signature = "v1=#{sign_payload(json_payload, timestamp)}"

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
          # @see app/jobs/decidim/rest_full/core/webhook_job.rb
          raise ::Decidim::RestFull::WebhookFailedError unless response.code.to_i.between?(200, 300)

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
end
