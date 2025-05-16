# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Spaces::SpacesController do
  path "/spaces/search" do
    get "Search Participatory Spaces" do
      tags "Spaces"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "searchSpaces"
      description "List or search spaces of the organization. Can be processes, assemblies, or any other registred participatory space."
      let!(:component_list) do
        Array.new(3) do
          proposals = create(:component, participatory_space: assembly, manifest_name: "proposals", published_at: Time.zone.now)
          create(:proposal, component: proposals)
          create(:proposal, component: proposals)

          meeting = create(:component, participatory_space: assembly, manifest_name: "meetings", published_at: Time.zone.now)
          create(:meeting, component: meeting)
          create(:meeting, component: meeting)
          [meeting, proposals]
        end.flatten
      end
      let!(:space_list) do
        Array.new(3) do
          create(:assembly, organization: organization)
          create(:participatory_process, organization: organization)
        end.flatten
      end
      let!(:assembly) { create(:assembly, id: 6, organization: organization, title: { en: "My assembly for testing purpose", fr: "c'est une assemblée" }) }
      let(:Authorization) { "Bearer #{impersonation_token.token}" }
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
      let!(:api_client) do
        api_client = create(:api_client, scopes: ["public"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "public.space.read")
        ]
        api_client.save!
        api_client.reload
      end
      let!(:organization) { create(:organization) }

      before do
        host! organization.host
        Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }.each do |manifest_name|
          create(:component, participatory_space: assembly, manifest_name: manifest_name, published_at: Time.zone.now)
        end
      end

      it_behaves_like "localized endpoint"
      it_behaves_like "paginated endpoint"
      it_behaves_like "filtered endpoint", filter: "manifest_name", item_schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name) }, exclude_filters: %w(lt gt start not_start matches does_not_match present blank)
      it_behaves_like "filtered endpoint", filter: "id", item_schema: { type: :integer }, exclude_filters: %w(lt gt start not_start matches does_not_match present blank)
      it_behaves_like "filtered endpoint", filter: "title", item_schema: { type: :string }, exclude_filters: %w(lt gt)

      response "200", "Search Results" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:space_index_response)

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
            expect(relationships["components"]["data"].count { |r| r["type"] == "proposal_component" }).to eq(4)
            expect(relationships["components"]["data"].count { |r| r["type"] == "meeting_component" }).to eq(4)
            expect(relationships["components"]["data"].count { |r| r["type"] == "blog_component" }).to eq(1)
            expect(relationships["components"]["data"].count { |r| r["type"] == "budget_component" }).to eq(1)
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

        context "with filter[id_in][] in a list of 3 ids" do
          let(:"filter[id_in][]") { space_list.map(&:id) }

          run_test!(example_name: :filter_by_id_in) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.size).to eq(3)
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
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with invalid locales[] fields" do
          let(:"locales[]") { ["invalid_locale"] }

          run_test! do |example|
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to start_with("Not allowed locales:")
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with no public scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no public.space.read permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["public"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Spaces::SpacesController.new
          allow(controller).to receive(:search).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Spaces::SpacesController).to receive(:new).and_return(controller)
        end

        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
