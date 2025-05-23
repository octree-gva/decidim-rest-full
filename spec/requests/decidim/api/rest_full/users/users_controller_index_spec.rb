# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::UsersController do
  path "/users" do
    get "List available Users" do
      tags "Users"
      produces "application/json"
      operationId "users"
      description "List or search users of the organization"
      it_behaves_like "paginated params"
      it_behaves_like "filtered params", filter: "nickname", item_schema: { type: :string }, only: :string
      it_behaves_like "filtered params", filter: "id", item_schema: { type: :integer }, only: :integer
      parameter name: :"filter[extended_data_cont]",
                schema: { type: :string },
                in: :query,
                required: false,
                example: '"foo": "bar"',
                description: 'Search on user extended_data. use the format: `"<key>":<space>"<value>"`'

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Users::UsersController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["oauth"],
        permissions: ["oauth.read"]
      ) do
        response "200", "Users listed" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:user_index_response)

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

          context "without oauth.extended_data.read permission" do
            context "and return empty extended_data" do
              before do
                create(:user, nickname: "specific-data", extended_data: { "key.path.is.awesome" => "bar" }, organization: organization)
                create_list(:user, 5, organization: organization)
              end

              run_test! do |example|
                data = JSON.parse(example.body)["data"]
                expect(data.reject { |d| d["attributes"]["extended_data"].empty? }).to be_empty
              end
            end
          end

          context "with oauth.extended_data.read permission" do
            let(:api_client) do
              api_client = create(:api_client, organization: organization, scopes: "oauth")
              api_client.permissions = [
                api_client.permissions.build(permission: "oauth.read"),
                api_client.permissions.build(permission: "oauth.extended_data.read")
              ]
              api_client.save!
              api_client
            end

            context "with filter[extended_data_cont] results" do
              before do
                create(:user, nickname: "specific-data", extended_data: { "key" => { "is" => "awesome" } }, organization: organization)
                create_list(:user, 5, organization: organization)
              end

              let(:"filter[extended_data_cont]") do
                '"key": {"is": "awesome"}'
              end

              run_test!(example_name: :filter_by_extended_data) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data.size).to eq(1)
                expect(data.first["attributes"]["nickname"]).to eq("specific-data")
              end
            end

            context "with filter[extended_data_cont], no results" do
              before do
                create(:user, nickname: "specific-data", extended_data: { foo: "404" }, organization: organization)
                create_list(:user, 5, organization: organization)
              end

              let(:"filter[extended_data_cont]") do
                '"foo": "bar"'
              end

              run_test!(example_name: :filter_by_extended_data) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data.size).to eq(0)
              end
            end
          end

          context "with filter[id_in][] in a list of 5 ids" do
            let(:user_list) { create_list(:user, 5, organization: organization) }
            let(:"filter[id_in][]") { user_list.map(&:id) }

            run_test!(example_name: :filter_by_id_in) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.size).to eq(5)
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

          it_behaves_like "paginated endpoint" do
            let(:create_resource) { -> { create(:user, organization: organization) } }
            let(:each_resource) { ->(_resource, _index) {} }
            let(:resources) { Decidim::User.all }
          end
        end

        response "403", "Forbidden" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          context "with extended_data_cont" do
            before do
              create(:user, nickname: "specific-data", extended_data: { foo: "bar" }, organization: organization)
              create_list(:user, 5, organization: organization)
            end

            let(:"filter[extended_data_cont]") do
              '"foo": "bar"'
            end

            run_test! do |_example|
              expect(response).to have_http_status(:forbidden)
              expect(response.body).to include("Forbidden")
            end
          end
        end
      end
    end
  end
end
