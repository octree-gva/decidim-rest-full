# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::MagicLinksController do
  path "/me/magic_links/{magic_token}" do
    get "Use a magic-lick" do
      tags "Users"
      consumes "text/html"
      produces "application/json"
      security []
      operationId "magicLinkSignin"
      description <<~README
        Challenge given token, open and a session and redirect. Publically accessible by HTTP.
      README

      parameter name: "magic_token", in: :path, schema: { type: :string, description: "A token received for magic link" }

      let!(:organization) { create(:organization) }
      let(:magic_token) { user.rest_full_generate_magic_token.magic_token }

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["oauth"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "oauth.magic_link")
        ]
        api_client.save!
        api_client.reload
      end

      let(:user) { create(:user, locale: "fr", organization: organization, confirmed_at: Time.zone.now) }

      before do
        host! organization.host
      end

      response "302", "Signed in" do
        produces "html/text"
        context "when token is valid" do
          run_test!(example_name: :ok) do |example|
            expect(example.body).to include("You are being ")
          end
        end
      end

      response "400", "Bad Request" do
        consumes "text/html"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
        context "when user is blocked" do
          before do
            user.update(blocked_at: Time.zone.now)
          end

          run_test!(example_name: :bad_blocked)
        end

        context "when token is wrong" do
          let(:magic_token) { "invalidToken" }

          run_test!(example_name: :bad_token)
        end

        context "when token is expired" do
          let(:magic_token) do
            token = create(:magic_token, magic_token: "uniqueToken", expires_at: 2.days.ago, user: user)
            token.magic_token
          end

          run_test!(example_name: :bad_token_expired)
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Users::MagicLinksController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Users::MagicLinksController).to receive(:new).and_return(controller)
        end

        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        run_test!(:server_error) do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
