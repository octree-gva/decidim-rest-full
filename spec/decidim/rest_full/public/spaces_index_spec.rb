# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Public::SpacesController", type: :request do
  path "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/public/spaces" do
    get "List Participatory Spaces" do
      tags "Public"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      Api::Definitions::FILTER_PARAM.call("manifest_name", { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name) }).each do |param|
        parameter(**param)
      end
      Api::Definitions::FILTER_PARAM.call("title", { type: :string }).each do |param|
        parameter(**param)
      end
      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
      let!(:organization) { create(:organization) }
      let!(:api_client) { create(:api_client, organization: organization) }
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
      let(:Authorization) { "Bearer #{impersonation_token.token}" }

      before do
        host! organization.host
        create(:assembly, organization: organization, title: { en: "My assembly for testing purpose", fr: "c'est une assemblée" })
        create(:assembly, organization: organization)
        create(:participatory_process, organization: organization)
      end

      response "200", "Search Results" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/space_response"

        context "with no filter params" do
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :ok)
        end

        context "with filter[manifest_name_in][] filter" do
          let(:"filter[manifest_name_in][]") { %w(assemblies) }
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :manifest_name_in_Assemblies) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data).to eq(data.select { |resp| resp["attributes"]["manifest_name"] == "assemblies" })
          end
        end

        context "with filter[title_eq] filter" do
          let(:"filter[title_eq]") { "My assembly for testing purpose" }
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :search_translatable_text) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.first["attributes"]["title"]["en"]).to eq("My assembly for testing purpose")
            expect(data.first["attributes"]["title"]["fr"]).to eq("c'est une assemblée")
            expect(data.size).to eq(1)
          end
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
          controller = Decidim::Api::RestFull::Public::SpacesController.new
          allow(controller).to receive(:index).and_raise(StandardError)
          allow(Decidim::Api::RestFull::Public::SpacesController)
            .to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"
        run_test!(example_name: :server_error)
      end
    end
  end
end
