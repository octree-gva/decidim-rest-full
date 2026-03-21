# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::MagicLinksController do
  path "/me/magic_links" do
    post "Create a magic link" do
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
            title: "Generate Magic Link Data",
            type: :object,
            properties: {
              redirect_url: { type: :string, description: "Optional HTTPS redirect URL after sign-in (host must be allowlisted)" }
            },
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
        let(:body) { {} }

        response "201", "Magick link created" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:magic_link_item_response)

          context "when user is valid" do
            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              token = data["attributes"]["token"]
              expect(token).to be_present
              expect(data["attributes"]["redirect_url"]).to be_nil
              expect(data["links"]["sign_in"]["href"]).to eq("https://#{organization.host}/api/rest_full/v#{Decidim::RestFull.major_minor_version}/me/magic_links/#{token}")
            end
          end

          context "when redirect_url is valid" do
            before do
              organization.update!(external_domain_allowlist: ["partner.example"])
            end

            let(:body) { { data: { redirect_url: "https://www.partner.example/callback?x=1" } } }

            run_test!(example_name: :ok_with_redirect) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["redirect_url"]).to eq("https://www.partner.example/callback?x=1")
            end
          end
        end

        response "400", "Bad Request" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)
          context "when user is blocked" do
            before do
              user.update(blocked_at: Time.zone.now)
            end

            run_test!(example_name: :bad_blocked)
          end
        end

        response "422", "Validation error" do
          consumes "application/json"
          produces "application/json"
          schema(
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    attribute: { type: :string },
                    message: { type: :string }
                  }
                }
              }
            },
            required: [:errors]
          )

          context "when redirect_url uses http" do
            before { organization.update!(external_domain_allowlist: ["partner.example"]) }

            let(:body) { { data: { redirect_url: "http://partner.example/x" } } }

            run_test!(example_name: :bad_redirect_http) do
              json = response.parsed_body
              expect(json["errors"]).to be_a(Array)
              expect(json["errors"].first["attribute"]).to eq("redirect_url")
            end
          end

          context "when redirect_url host is not allowed" do
            let(:body) { { data: { redirect_url: "https://evil.test/" } } }

            run_test!(example_name: :bad_redirect_host) do
              json = response.parsed_body
              expect(json["errors"]).to be_a(Array)
              expect(json["errors"].first["attribute"]).to eq("redirect_url")
            end
          end
        end
      end
    end
  end
end
