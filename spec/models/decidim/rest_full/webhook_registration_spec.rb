# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    RSpec.describe WebhookRegistration do
      let(:webhook_registration) { create(:webhook_registration) }

      describe "when validating" do
        it "is invalid without a URL" do
          webhook_registration.url = nil
          expect(webhook_registration).not_to be_valid
          expect(webhook_registration.errors[:url]).to include("cannot be blank")
        end

        it "is invalid with empty subscriptions" do
          webhook_registration.subscriptions = []
          expect(webhook_registration).not_to be_valid
          expect(webhook_registration.errors[:subscriptions]).to include("cannot be blank")
        end

        it "is invalid without an API client" do
          webhook_registration.api_client = nil
          webhook_registration.api_client_id = nil
          expect(webhook_registration).not_to be_valid
          expect(webhook_registration.errors[:api_client]).to include("must exist")
        end

        it "is invalid if API Client does not exist" do
          webhook_registration.api_client = nil
          webhook_registration.api_client_id = 404
          expect(webhook_registration).not_to be_valid
          expect(webhook_registration.errors[:api_client]).to include("must exist")
        end
      end

      context "when regenerating private key" do
        it "Regenerates the private key if it is not 64 characters long" do
          webhook_registration.private_key = "1234567890"
          webhook_registration.valid?
          expect(webhook_registration.private_key.length).to eq(64)
          expect(webhook_registration.private_key).not_to eq("1234567890")
        end

        it "Regenerates the private key if it is nil" do
          webhook_registration.private_key = nil
          webhook_registration.valid?
          expect(webhook_registration.private_key.length).to eq(64)
          expect(webhook_registration.private_key).not_to be_nil
        end

        it "Does not regenerate the private key if it is 64 characters long" do
          custom_key = SecureRandom.hex(32)
          webhook_registration.private_key = custom_key
          webhook_registration.valid?
          expect(webhook_registration.private_key.length).to eq(64)
          expect(webhook_registration.private_key).to eq(custom_key)
        end
      end

      describe "#send_webhook" do
        let(:timestamp) { Time.current.to_i.to_s }
        let(:event) { { "type" => "test.event", "data" => { "data" => "test" } } }
        let(:url) { "https://example.com/webhook" }

        let(:mock_http) { instance_double(Net::HTTP) }
        let(:mock_response) { instance_double(Net::HTTPResponse) }

        before do
          allow(Net::HTTP).to receive(:start).and_yield(mock_http)
          allow(mock_http).to receive(:request).and_return(mock_response)
          allow(mock_response).to receive_messages(code: "200", body: "OK")
        end

        describe ".body" do
          it "takes event.type as event name" do
            expect(mock_http).to receive(:request) do |request|
              body = JSON.parse(request.body)
              expect(body["event"]).to eq("test.event")
              mock_response
            end

            webhook_registration.send_webhook(event, timestamp)
          end

          it "takes event.data.data as payload data" do
            expect(mock_http).to receive(:request) do |request|
              body = JSON.parse(request.body)
              expect(body["data"]).to eq("test")
              mock_response
            end

            webhook_registration.send_webhook(event, timestamp)
          end
        end

        describe ".headers" do
          it "includes a json content type" do
            expect(mock_http).to receive(:request) do |request|
              expect(request["Content-Type"]).to eq("application/json")
              mock_response
            end

            webhook_registration.send_webhook(event, timestamp)
          end

          it "includes a webhook signature of <timestamp>.<request.body> signed with the private key" do
            expect(mock_http).to receive(:request) do |request|
              expect(request["X-Webhook-Signature"]).to be_present
              local_timestamp = request["X-Webhook-Timestamp"]
              data = "#{local_timestamp}.#{request.body}"
              # Sign the data
              signature = OpenSSL::HMAC.hexdigest("SHA256", webhook_registration.private_key, data)
              expect(request["X-Webhook-Signature"]).to eq(signature)
              mock_response
            end

            webhook_registration.send_webhook(event, timestamp)
          end

          it "includes a webhook timestamp" do
            expect(mock_http).to receive(:request) do |request|
              expect(request["X-Webhook-Timestamp"]).to be_present
              mock_response
            end

            webhook_registration.send_webhook(event, timestamp)
          end
        end

        context "when handling errors" do
          it "raises a WebhookFailedError error when the response is not 200" do
            allow(mock_response).to receive_messages(code: "405")
            expect { webhook_registration.send_webhook(event, timestamp) }.to raise_error(WebhookFailedError)
          end

          it "does not raise an error when the response is 200" do
            allow(mock_response).to receive_messages(code: "200")
            expect { webhook_registration.send_webhook(event, timestamp) }.not_to raise_error(WebhookFailedError)
          end
        end
      end
    end
  end
end
