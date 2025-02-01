# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::User::MeController, type: :request do
  path "/me/magic-links/{magic_token}" do
    get "Use a magic-lick" do
      tags "Users"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["oauth"] }]
      operationId "magicLinkSignin"
      description <<~README
        Challenge given token, open and a session and redirect
      README

      parameter name: "magic_token", in: :path, schema: { type: :string, description: "A token received for magic link" }

      let!(:organization) { create(:organization) }
      let(:magic_token) { user.rest_full_generate_magic_token.magic_token }

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["oauth"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "oauth.login")
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

      response "302", "Signed in" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/magic_link_redirect_response"

        context "when token is valid" do
          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            token = user.rest_full_magic_token.magic_token
            expect(data["links"]["self"]["href"]).to eq("https://#{organization.host}/api/rest_full/v0.0/me/magic-links/#{token}")
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

        context "when token is wrong" do
          let(:magic_token) { "invalid_token" }

          run_test!(example_name: :bad_token)
        end

        context "when token is expired" do
          let(:magic_token) do
            token = create(:magic_token, magic_token: "unique_token", expires_at: 2.days.ago, user: user)
            token.magic_token
          end

          run_test!(example_name: :bad_token_expired)
        end
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

        context "with no oauth.login permission" do
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
          controller = Decidim::Api::RestFull::User::MeController.new
          allow(controller).to receive(:signin_magic_link).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::User::MeController).to receive(:new).and_return(controller)
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
