# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Public::SpacesController", type: :request do
  path "/public/spaces" do
    get "List Participatory Spaces" do
      tags "Public"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      Api::Definitions::FILTER_PARAM.call(
        "manifest_name",
        { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name) },
        %w(lt gt start not_start matches does_not_match present blank)
      ).each do |param|
        parameter(**param)
      end
      Api::Definitions::FILTER_PARAM.call("title", { type: :string }, %w(lt gt)).each do |param|
        parameter(**param)
      end
      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
      let!(:organization) { create(:organization) }
      let!(:api_client) { create(:api_client, organization: organization) }
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

      let(:Authorization) { "Bearer #{impersonation_token.token}" }
      let!(:assembly) { create(:assembly, id: 6, organization: organization, title: { en: "My assembly for testing purpose", fr: "c'est une assemblée" }) }

      let!(:space_list) do
        3.times do
          create(:assembly, organization: organization)
          create(:participatory_process, organization: organization)
        end
      end

      let!(:component_list) do
        3.times.map do
          proposals = create(:component, participatory_space: assembly, manifest_name: "proposals", published_at: Time.zone.now)
          create(:proposal, component: proposals)
          create(:proposal, component: proposals)

          meeting = create(:component, participatory_space: assembly, manifest_name: "meetings", published_at: Time.zone.now)
          create(:meeting, component: meeting)
          create(:meeting, component: meeting)
          [meeting, proposals]
        end.flatten
      end

      before do
        host! organization.host
        Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }.each do |manifest_name|
          create(:component, participatory_space: assembly, manifest_name: manifest_name, published_at: Time.zone.now)
        end
      end

      response "200", "Search Results" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/spaces_response"

        context "with no filter params" do
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            assembly = Decidim::Assembly.find(6)
            assembly_data = data.find { |result| result["id"] == assembly.id.to_s && result["attributes"]["manifest_name"] == "assemblies" }
            expect(assembly_data).to be_truthy
            relationships = assembly_data["relationships"]
            expect(relationships["components"]["data"].select { |r| r["type"] == "proposal_component" }.size).to eq(4)
            expect(relationships["components"]["data"].select { |r| r["type"] == "meeting_component" }.size).to eq(4)
            expect(relationships["components"]["data"].select { |r| r["type"] == "blog_component" }.size).to eq(1)
            expect(relationships["components"]["data"].select { |r| r["type"] == "budget_component" }.size).to eq(1)
          end
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
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to start_with("Not allowed locales:")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Public::SpacesController.new
          allow(controller).to receive(:index).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Public::SpacesController).to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Intentional error for testing")
        end
      end
    end
  end
end
