# frozen_string_literal: true

# spec/integration/api/rest_full/system/organizations_spec.rb
require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::System::OrganizationsController", type: :request do
  path "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/system/organizations" do
    get "List available organizations" do
      tags "System"
      produces "application/json"
      security [{ credentialFlowBearer: [] }]
      parameter name: "populate[]", in: :query, style: :form, explode: true, schema: Api::Definitions::POPULATE_PARAM.call(Decidim::Api::RestFull::OrganizationSerializer), required: false
      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false

      let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "system").token}" }

      response "200", "Organizations listed" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/organizations_response"

        context "with populate[] and locale[] filter displayed fields and translated results" do
          let(:"populate[]") { Decidim::Api::RestFull::OrganizationSerializer.db_fields }
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
        schema "$ref" => "#/components/schemas/error"
        context "with invalid populate[] fields" do
          let(:"populate[]") { ["invalid_field"] }

          run_test!(example_name: :bad_format) do |example|
            message = JSON.parse(example.body)["detail"]
            expect(message).to start_with("Not allowed populate param: invalid_field")
          end
        end

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

        schema "$ref" => "#/components/schemas/error"
        run_test!(example_name: :server_error)
      end
    end
  end
end
