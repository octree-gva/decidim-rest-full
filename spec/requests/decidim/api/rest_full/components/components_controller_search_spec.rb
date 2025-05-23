# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::ComponentsController do
  path "/components/search" do
    get "Search components" do
      tags "Components"
      produces "application/json"
      operationId "searchComponents"
      description "List or search components of the organization"
      it_behaves_like "paginated params"
      it_behaves_like "localized params"
      it_behaves_like "filtered params", filter: "manifest_name", item_schema: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:component_manifest) }, only: :string
      it_behaves_like "filtered params", filter: "id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered params", filter: "participatory_space_id", item_schema: { type: :string }, only: :integer
      it_behaves_like "filtered params", filter: "participatory_space_type", item_schema: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:space_type) }, only: :string
      it_behaves_like "filtered params", filter: "name", item_schema: { type: :string }, only: :string

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Components::ComponentsController,
        action: :search,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["public"],
        permissions: ["public.component.read"]
      ) do
        let(:component) { create(:component, participatory_space: participatory_process, manifest_name: "meetings", published_at: Time.zone.now) }
        let!(:assembly) { create(:assembly, organization: organization) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
        let!(:organization) { create(:organization) }

        before do
          create(:meeting, component: component)
          create(:meeting, component: component)

          proposals = create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now)
          create(:proposal, component: proposals)
          create(:proposal, component: proposals)

          create(
            :proposal_component,
            :with_votes_enabled,
            participatory_space: participatory_process,
            settings: { awesome_voting_manifest: :voting_cards }
          )

          accountabilities = create(:accountability_component, participatory_space: participatory_process, published_at: Time.zone.now)
          create(:result, component: accountabilities)
          create(:result, component: accountabilities)
        end

        it_behaves_like "localized endpoint"

        response "200", "List of components" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:component_index_response)

          context "with no filter params" do
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :ok)
          end

          context "with filter[manifest_name_in][] filter" do
            let(:"filter[manifest_name_in][]") { %w(meetings) }
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :manifest_name_in_Meetings) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data).to eq(data.select { |resp| resp["attributes"]["manifest_name"] == "meetings" })
              expect(data).to eq(data.select { |resp| resp["type"] == "meeting_component" })
            end
          end

          context "with filter[id_in][] filter" do
            let(:last_two) { participatory_process.components.limit(2).ids }
            let(:"filter[id_in][]") { last_two }
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :filter_byId) do |example|
              data = JSON.parse(example.body)["data"]
              ids = last_two.map(&:to_s)
              expect(data.map { |d| d["id"] }).to match_array(ids)
            end
          end

          context "with filter[participatory_space_type_eq]=Decidim::ParticipatoryProcess and filter[participatory_space_type_id_eq]=processId filters" do
            let(:"filter[participatory_space_id_eq]") { participatory_process.id.to_s }
            let(:"filter[participatory_space_type_eq]") { "Decidim::ParticipatoryProcess" }
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :components_in_Process) do |example|
              data = JSON.parse(example.body)["data"]
              not_in_process = data.select { |component| component["attributes"]["participatory_space_type"] != "Decidim::ParticipatoryProcess" && component["attributes"]["participatory_space_id"] != participatory_process.id.to_s }
              expect(not_in_process).to be_empty
            end
          end

          it_behaves_like "paginated endpoint", sample_size: 11 do
            let(:manifests) { Decidim.component_registry.manifests.map(&:name).filter { |manifest| manifest != :dummy } }
            let(:create_resource) { -> { create(:component, participatory_space: assembly, manifest_name: manifests.sample, published_at: Time.zone.now) } }
            let(:each_resource) { ->(_resource, _index) {} }
            let(:resources) { Decidim::Component.all }
          end
        end
      end
    end
  end
end
