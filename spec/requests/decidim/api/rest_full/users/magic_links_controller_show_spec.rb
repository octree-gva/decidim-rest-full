# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::MagicLinksController do
  path "/me/magic_links/{magic_token}" do
    get "Use a magic-lick" do
      tags "Users"
      consumes "text/html"
      produces "application/json"
      operationId "magicLinkSignin"
      description <<~README
        Challenge given token, open and a session and redirect. Publically accessible by HTTP.
      README

      parameter name: "magic_token", in: :path, schema: { type: :string, description: "A token received for magic link" }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Users::MagicLinksController,
        action: :show,
        security_types: [:impersonationFlow],
        scopes: ["oauth"],
        permissions: ["oauth.magic_link"],
        is_protected: false
      ) do
        let(:magic_token) { user.rest_full_generate_magic_token.magic_token }

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
      end
    end
  end
end
