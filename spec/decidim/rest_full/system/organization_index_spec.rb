# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::System::OrganizationsController", type: :request do
  path "/system/organizations" do
    get "List available organizations" do
      tags "System"
      produces "application/json"
      security [{ credentialFlowBearer: ["system"] }]

      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
      let(:organization) { create(:organization) }
      let(:api_client) do
        api_client = create(:api_client, organization: organization, scopes: "system")
        api_client.permissions = [
          api_client.permissions.build(permission: "oauth.impersonate"),
          api_client.permissions.build(permission: "oauth.login"),
          api_client.permissions.build(permission: "system.organizations.read")
        ]
        api_client.save!
        api_client
      end
      let!(:user) { create(:user) }
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: user.id, application: api_client) }

      let(:Authorization) { "Bearer #{impersonation_token.token}" }

      before do
        create(:rest_full_permission, api_client: api_client, permission: "system.organization.read")
      end

      response "200", "Organizations listed" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/organizations_response"

        context "with locale[] filter translated results" do
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :ok)
        end

        context "with per_page=2, list max two organizations" do
          let(:page) { 1 }
          let(:per_page) { 2 }

          before do
            create(:organization)
            create(:organization)
            create(:organization)
          end

          run_test!(example_name: :paginated) do |example|
            json_response = JSON.parse(example.body)
            expect(json_response["data"].size).to eq(per_page)
          end
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with invalid locales[] fields" do
          let(:"locales[]") { ["invalid_locale"] }

          run_test! do |example|
            message = JSON.parse(example.body)["detail"]
            expect(message).to start_with("Not allowed locales:")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"
        before do
          controller = Decidim::Api::RestFull::System::OrganizationsController.new
          allow(controller).to receive(:index).and_raise(StandardError)
          allow(Decidim::Api::RestFull::System::OrganizationsController)
            .to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"
        run_test!(example_name: :server_error)
      end
    end
  end
end
