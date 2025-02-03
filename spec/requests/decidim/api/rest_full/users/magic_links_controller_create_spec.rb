# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::MagicLinksController, type: :request do
  path "/me/magic_links" do
    post "Create a magic-lick" do
      tags "Users"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["oauth"] }]
      operationId "generateMagicLink"
      description <<~README
        Generates a uniq magic link, valid for 5minutes. If the user follow this link, it will be signed in automatically
      README

      parameter name: :body, in: :body, schema: {
        title: "Magick Link Configuration Payload",
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              redirect_url: { type: :string, description: "Redirect url after sign-in" }
            },
            required: [:redirect_url],
            description: "Optional payload to configure the magic link"
          }
        }
      }

      let!(:organization) { create(:organization) }

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["oauth"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "oauth.magic_link")
        ]
        api_client.save!
        api_client.reload
      end

      let(:user) { create(:user, locale: "fr", organization: organization) }

      # Routing
      let!(:impersonate_token) do
        create(:oauth_access_token, scopes: ["oauth"], resource_owner_id: user.id, application: api_client)
      end

      let(:Authorization) { "Bearer #{impersonate_token.token}" }

      before do
        host! organization.host
      end

      response "201", "Magick link created" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/magic_link_response"

        context "when user is valid" do
          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            token = data["attributes"]["token"]
            expect(token).to be_present
            expect(data["links"]["sign_in"]["href"]).to eq("https://#{organization.host}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/me/magic-links/#{token}")
          end
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"
        context "when user is blocked" do
          before do
            user.update(blocked_at: Time.zone.now)
          end

          run_test!(example_name: :bad_blocked)
        end

        context "when user is locked"
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"
        context "with client credentials" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample" } } }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no oauth scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: user.id, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample" } } }

          run_test!(example_name: :forbidden_scope) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no oauth.magic_link permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["oauth"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "oauth", resource_owner_id: user.id, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample" } } }

          run_test! do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Users::MagicLinksController.new
          allow(controller).to receive(:create).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Users::MagicLinksController).to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"

        run_test!(:server_error) do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
