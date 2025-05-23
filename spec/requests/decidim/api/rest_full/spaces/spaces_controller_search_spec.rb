# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Spaces::SpacesController do
  path "/spaces/search" do
    get "Search Participatory Spaces" do
      tags "Spaces"
      produces "application/json"
      operationId "searchSpaces"
      description "List or search spaces of the organization. Can be processes, assemblies, or any other registred participatory space."
      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "filtered params", filter: "manifest_name", item_schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name) }, only: :string
      it_behaves_like "filtered params", filter: "id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered params", filter: "title", item_schema: { type: :string }, only: :string
      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Spaces::SpacesController,
        action: :search,
        security_types: [:credentialFlow, :impersonationFlow],
        scopes: ["public"],
        permissions: ["public.space.read"]
      ) do
        it_behaves_like "localized endpoint"

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
        let(:Authorization) { "Bearer #{bearer_token.token}" }
        let!(:bearer_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
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

          it_behaves_like "paginated endpoint" do
            let(:create_resource) { -> { create(:assembly, organization: organization) } }
            let(:each_resource) { ->(_resource, _index) {} }
            let(:resources) { Decidim::Assembly.all + Decidim::ParticipatoryProcess.all }
          end
        end
      end
    end
  end
end
