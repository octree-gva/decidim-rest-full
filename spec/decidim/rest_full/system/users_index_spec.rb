# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::OAuth::UsersController", type: :request do
  path "/system/users" do
    get "List available Users" do
      tags "System"
      produces "application/json"
      security [{ credentialFlowBearer: ["system"] }]

      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
      Api::Definitions::FILTER_PARAM.call("nickname", { type: :string }, %w(lt gt)).each do |param|
        parameter(**param)
      end
      parameter name: :"filter[extra_cont]",
                schema: { type: :string },
                in: :query,
                required: false,
                example: '"foo": "bar"',
                description: 'Search on user extended_data. use the format: `"<key>":<space>"<value>"`'

      let!(:organization) { create(:organization) }
      let(:Authorization) { "Bearer #{impersonation_token.token}" }
      let(:api_client) do
        api_client = create(:api_client, organization: organization, scopes: "system")
        api_client.permissions = [
          api_client.permissions.build(permission: "oauth.impersonate"),
          api_client.permissions.build(permission: "oauth.login"),
          api_client.permissions.build(permission: "system.users.read")
        ]
        api_client.save!
        api_client
      end
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

      before do
        host! organization.host
      end

      response "200", "Users listed" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/users_response"

        context "with no params" do
          before do
            create(:user, organization: organization)
            create_list(:user, 5, organization: organization)
          end

          run_test!(example_name: :ok)
        end

        context "with locale" do
          before do
            create(:user, locale: "fr", organization: organization)
          end

          run_test!(example_name: :user_fr) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.first["attributes"]["locale"]).to eq("fr")
          end
        end

        context "with filter[extra_cont] results" do
          before do
            create(:user, nickname: "specific-data", extended_data: { foo: "bar" }, organization: organization)
            create_list(:user, 5, organization: organization)
          end

          let(:"filter[extra_cont]") do
            '"foo": "bar"'
          end

          run_test!(example_name: :filter_by_extended_data) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.size).to eq(1)
            expect(data.first["attributes"]["nickname"]).to eq("specific-data")
          end
        end

        context "with filter[extra_cont], no results" do
          before do
            create(:user, nickname: "specific-data", extended_data: { foo: "404" }, organization: organization)
            create_list(:user, 5, organization: organization)
          end

          let(:"filter[extra_cont]") do
            '"foo": "bar"'
          end

          run_test!(example_name: :filter_by_extended_data) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.size).to eq(0)
          end
        end

        context "with filter[nickname_eq]" do
          before do
            create(:user, nickname: "blue-panda-218", organization: organization)
            create_list(:user, 5, organization: organization)
          end

          let(:"filter[nickname_eq]") { "blue-panda-218" }
          let(:page) { 1 }
          let(:per_page) { 2 }

          run_test!(example_name: :filter_by_nickname) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.size).to eq(1)
            expect(data.first["attributes"]["nickname"]).to eq("blue-panda-218")
          end
        end

        context "with per_page=2, list max two users" do
          let(:page) { 1 }
          let(:per_page) { 2 }

          before do
            5.times.each do
              create(:user, organization: organization)
            end
          end

          run_test!(example_name: :paginated) do |example|
            json_response = JSON.parse(example.body)
            expect(json_response["data"].size).to eq(per_page)
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"
        before do
          controller = Decidim::Api::RestFull::System::UsersController.new
          allow(controller).to receive(:index).and_raise(StandardError)
          allow(Decidim::Api::RestFull::System::UsersController)
            .to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"
        run_test!(example_name: :server_error)
      end
    end
  end
end