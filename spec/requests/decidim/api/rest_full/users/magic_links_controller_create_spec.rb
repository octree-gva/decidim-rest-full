# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::MagicLinksController do
  path "/me/magic_links" do
    post "Create a magic-lick" do
      tags "Users"
      produces "application/json"
      operationId "generateMagicLink"
      description <<~README
        Generates a uniq magic link, valid for 5minutes. If the user follow this link, it will be signed in automatically
      README

      parameter name: :body, in: :body, schema: {
        title: "Generate Magic Link Payload",
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

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Users::MagicLinksController,
        action: :create,
        security_types: [:impersonationFlow],
        scopes: ["oauth"],
        permissions: ["oauth.magic_link"]
      ) do
        response "201", "Magick link created" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:magic_link_item_response)

          context "when user is valid" do
            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              token = data["attributes"]["token"]
              expect(token).to be_present
              expect(data["links"]["sign_in"]["href"]).to eq("https://#{organization.host}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/me/magic_links/#{token}")
            end
          end
        end

        response "400", "Bad Request" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          context "when user is blocked" do
            before do
              user.update(blocked_at: Time.zone.now)
            end

            run_test!(example_name: :bad_blocked)
          end
        end
      end
    end
  end
end
