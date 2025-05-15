# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Metrics::HealthController, type: :request do
  path "/metrics/health" do
    get "Health" do
      tags "Metrics"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "health-metrics"
      description "Health metrics"

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["public"], organization: organization)
        api_client.permissions = []
        api_client.save!
        api_client.reload
      end
      let(:asset_mock) do
        asset_file = "media/images/default-avatar.svg"
        asset_relative_path = ActionController::Base.helpers.asset_pack_url(asset_file)
        stub_request(:head, "http://#{organization.host}#{asset_relative_path}")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "Ruby"
            }
          )
      end

      let!(:organization) { create(:organization) }

      let!(:api_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

      let(:Authorization) { "Bearer #{api_token.token}" }

      before do
        host! organization.host
      end

      response "503", "Unhealthy services" do
        produces "application/json"
        schema type: :object, properties: {
          message: { type: :string, enum: %w(OK ERROR) }
        }, required: ["message"]
        context "when DB is not accessible" do
          before do
            allow(ActiveRecord::Base.connection).to receive(:active?).and_return(false)
            asset_mock.to_return(status: 200, body: "", headers: {})
          end

          run_test!(example_name: :error_db)
        end

        context "when public assets are not accessible" do
          before do
            asset_mock.to_return(status: 404, body: "", headers: {})
          end

          run_test!(example_name: :error_public_assets)
        end

        context "when cache fails to write" do
          before do
            asset_mock.to_return(status: 200, body: "", headers: {})
            allow(Rails.cache).to receive(:write).and_raise(StandardError)
          end

          run_test!(example_name: :error_cache)
        end

        context "when referer does not match any organization" do
          before do
            asset_mock.to_return(status: 200, body: "", headers: {})
            allow(Rails.cache).to receive(:write).and_raise(StandardError)
            organization.update(host: "unknown.localhost")
          end

          run_test!(example_name: :error_referer)
        end
      end

      response "200", "Healthy services" do
        produces "application/json"
        schema type: :object, properties: {
          message: { type: :string, enum: %w(OK ERROR) }
        }, required: ["message"]

        context "when healthy" do
          before do
            asset_mock.to_return(status: 200, body: "", headers: {})
          end

          run_test!(example_name: :ok)
        end
      end
    end
  end
end
