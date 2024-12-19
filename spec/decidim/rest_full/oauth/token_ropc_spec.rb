# frozen_string_literal: true

# spec/integration/oauth_scopes_spec.rb
require "swagger_helper"
def uniq_nickname
  final_nickname = nickname = "decidimuser"
  i = 0
  while Decidim::User.find_by(nickname: final_nickname)
    i += 1
    final_nickname = "#{nickname}_#{i}"
  end
  final_nickname
end
RSpec.describe "Decidim::Api::RestFull::System::ApplicationController", type: :request do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization, password: "decidim123456789!", password_confirmation: "decidim123456789!") }
  let!(:api_client) do
    api_client = create(:api_client, organization: organization, scopes: %w(oauth public))
    api_client.permissions = [
      api_client.permissions.build(permission: "oauth.impersonate"),
      api_client.permissions.build(permission: "oauth.login")
    ]
    api_client.save!
    api_client.reload
  end

  before do
    host! organization.host
  end

  path "/oauth/token" do
    post "Request a OAuth token throught ROPC" do
      tags "OAuth"
      consumes "application/json"
      produces "application/json"
      security([])
      operationId "createToken"
      description "Create a oauth token for the given scopes"

      parameter name: :body, in: :body, required: true, schema: { "$ref" => "#/components/schemas/oauth_grant_param" }
      response "200", "Token returned" do
        context "when user does not exists" do
          context "with meta.register_on_missing=true" do
            let(:nickname) { uniq_nickname }
            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                meta: {
                  register_on_missing: true
                },
                scope: "public"
              }
            end

            run_test! do |_example|
              expect(Decidim::User.find_by(nickname: nickname)).to be_truthy
            end
          end

          context "with meta.register_on_missing=true and meta.email=an_email" do
            let(:nickname) { uniq_nickname }
            let(:email) do
              "test#{Devise.friendly_token.first(10).downcase}@example.org"
            end
            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                meta: {
                  register_on_missing: true,
                  email: email
                },
                scope: "public"
              }
            end

            run_test! do |_example|
              created_user = Decidim::User.find_by(nickname: nickname)
              expect(created_user).to be_truthy
              expect(created_user.email).to eq(email)
              expect(created_user.extended_data).to eq({})
            end
          end

          context "with meta.register_on_missing=true and extra.foo=bar" do
            let(:nickname) { uniq_nickname }

            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                meta: {
                  register_on_missing: true
                },
                extra: {
                  foo: "bar"
                },
                scope: "public"
              }
            end

            run_test! do |_example|
              created_user = Decidim::User.find_by(nickname: nickname)
              expect(created_user).to be_truthy
              expect(created_user.email).to end_with("example.org")
              expect(created_user.extended_data).to eq({ "foo" => "bar" })
            end
          end

          context "with meta.register_on_missing=true and meta.name='My Name'" do
            let(:nickname) { uniq_nickname }

            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                meta: {
                  register_on_missing: true,
                  name: "My Name"
                },
                extra: {},
                scope: "public"
              }
            end

            run_test! do |_example|
              created_user = Decidim::User.find_by(nickname: nickname)
              expect(created_user).to be_truthy
              expect(created_user.name).to eq("My Name")
              expect(created_user.extended_data).to eq({})
            end
          end
        end

        context "when user does exists" do
          context "with auth_type=impersonate and extra.foo=bar" do
            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: user.nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                extra: {
                  foo: "bar"
                },
                scope: "public"
              }
            end

            run_test!(example_name: :ok_ropc_impersonate_with_extra) do |_response|
              expect(user.reload.extended_data).to eq({ "foo" => "bar" })
            end
          end

          context "with auth_type=impersonate and finding by id" do
            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                id: user.id,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                scope: "public"
              }
            end

            run_test!(example_name: :ok_ropc_impersonate_with_extra) do |response|
              json_response = JSON.parse(response.body)
              expect(json_response["access_token"]).to be_present
              access_token = Doorkeeper::AccessToken.find_by(token: json_response["access_token"])
              expect(
                access_token.resource_owner_id
              ).to eq(user.id)
            end
          end

          context "with auth_type=impersonate" do
            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: user.nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                scope: "public"
              }
            end

            run_test!(example_name: :ok_ropc_impersonate) do |response|
              json_response = JSON.parse(response.body)
              expect(json_response["access_token"]).to be_present
              expect(
                Doorkeeper::AccessToken.find_by(token: json_response["access_token"]).scopes
              ).to include("public")
            end
          end

          context "with auth_type=login" do
            let(:proposal_api_client) do
              api_client = create(:api_client, organization: organization, scopes: "proposals public")
              api_client.permissions = [
                api_client.permissions.build(permission: "oauth.login")
              ]
              api_client.save!
              api_client
            end

            let(:body) do
              {
                grant_type: "password",
                auth_type: "login",
                password: "decidim123456789!",
                username: user.nickname,
                client_id: proposal_api_client.client_id,
                client_secret: proposal_api_client.client_secret,
                scope: "public proposals"
              }
            end

            run_test!(example_name: :ok_ropc_login) do |response|
              json_response = JSON.parse(response.body)
              expect(json_response["access_token"]).to be_present
              expect(
                Doorkeeper::AccessToken.find_by(token: json_response["access_token"]).scopes
              ).to include("proposals")
            end
          end
        end
      end

      response "400", "Bad Request" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "when user does not exists" do
          context "with meta.register_on_missing=false" do
            let(:nickname) { uniq_nickname }
            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                meta: {
                  register_on_missing: false
                },
                scope: "public"
              }
            end

            run_test!(example_name: :user_not_found) do |_example|
              expect(Decidim::User.find_by(nickname: nickname)).to be_nil
            end
          end

          context "with meta.register_on_missing=true and invalid username" do
            let(:nickname) { uniq_nickname }
            let(:body) do
              {
                grant_type: "password",
                auth_type: "impersonate",
                username: nickname,
                client_id: api_client.client_id,
                client_secret: api_client.client_secret,
                meta: {
                  register_on_missing: false
                },
                scope: "public"
              }
            end

            run_test!(example_name: :invalid_username_on_register) do |_example|
              expect(Decidim::User.find_by(nickname: nickname)).to be_nil
            end
          end
        end

        context "with client_id from another organization" do
          let(:organization_b) { create(:organization) }
          let(:foreign_api_client) { create(:api_client, organization: organization_b, scopes: %w(oauth public)) }
          let(:body) do
            {
              grant_type: "password",
              username: user.nickname,
              auth_type: "impersonate",
              client_id: foreign_api_client.client_id,
              client_secret: foreign_api_client.client_secret,
              scope: "public"
            }
          end

          before do
            host! organization.host
          end

          run_test!(example_name: :bad_request)
        end

        context "with impersonate username from an another tenant" do
          let(:other_tenant) { create(:organization) }
          let(:body) do
            {
              grant_type: "password",
              username: user.nickname,
              auth_type: "impersonate",
              client_id: api_client.client_id,
              client_secret: api_client.client_secret,
              scope: "public"
            }
          end

          before { host! other_tenant.host }

          run_test!
        end

        context "with scope=system and password grant" do
          let(:system_api_client) { create(:api_client, organization: organization, scopes: "system") }
          let(:body) do
            {
              grant_type: "password",
              username: user.nickname,
              auth_type: "impersonate",
              client_id: system_api_client.client_id,
              client_secret: system_api_client.client_secret,
              scope: "system"
            }
          end

          run_test!
        end
      end
    end
  end
end
