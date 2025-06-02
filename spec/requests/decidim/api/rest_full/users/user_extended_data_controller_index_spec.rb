# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Users::UserExtendedDataController do
  path "/me/extended_data" do
    get "Get user extended data" do
      tags "Users"
      produces "application/json"
      operationId "userData"
      description "Fetch user extended data"
      parameter name: "object_path", in: :query, required: true, schema: { type: :string, description: "object path, in dot style, like foo.bar" }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Users::UserExtendedDataController,
        action: :index,
        security_types: [:impersonationFlow],
        scopes: ["oauth"],
        permissions: ["oauth.extended_data.read"]
      ) do
        let!(:user_id) { user.id }
        let!(:object_path) { "custom.data" }

        response "200", "Extended Data for a given object_path given" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:user_extended_data)
          context "with extended_data={'foo' => {'bar' => 'true'}}, can access object_path=foo.bar" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "foo" => { "bar" => "true" } }) }
            let!(:object_path) { "foo.bar" }

            run_test! do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to eq("true")
            end
          end

          context "with extended_data={'personal' => {'birthday' => '1989-01-28'}}, can access object_path=personal" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
            let!(:object_path) { "personal" }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include({ "birthday" => "1989-01-28" })
            end
          end

          context "with extended_data=<whatever object>, can access object_path=." do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
            let!(:object_path) { "." }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(response).to have_http_status(:ok)
              expect(data).to include({ "personal" => { "birthday" => "1989-01-28" } })
            end
          end
        end

        response "404", "Not Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "with a object_path=unknown" do
            let(:user) { create(:user, locale: "fr", organization: organization, extended_data: { "personal" => { "birthday" => "1989-01-28" } }) }
            let!(:object_path) { "unknown" }

            run_test!(example_name: :not_found)
          end
        end
      end
    end
  end
end
