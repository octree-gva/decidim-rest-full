# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::BlogComponentsController do
  path "/components/blog_components" do
    get "Blog Components" do
      tags "Components"
      produces "application/json"
      operationId "blog_components"
      description "List or search blog components of the organization"
      it_behaves_like "paginated params"
      it_behaves_like "localized params"
      it_behaves_like "filtered params", filter: "participatory_space_id", item_schema: { type: :string }, only: :integer
      it_behaves_like "filtered params", filter: "participatory_space_type", item_schema: { type: :string, example: "Decidim::Assembly" }, only: :string
      it_behaves_like "filtered params", filter: "name", item_schema: { type: :string }, only: :string

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Components::BlogComponentsController,
        action: :index,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["public"],
        permissions: ["public.component.read"]
      ) do
        let(:component) { create(:component, manifest_name: "blogs") }
        let!(:assembly) { create(:assembly, organization: organization) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
        let!(:organization) { create(:organization) }

        before do
          proposals = create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now)
          create(:proposal, component: proposals)
          create(:proposal, component: proposals)

          create(
            :component,
            manifest_name: "blogs",
            participatory_space: participatory_process,
            settings: { awesome_voting_manifest: :voting_cards }
          )
        end

        it_behaves_like "localized endpoint"

        response "200", "List of blog components" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:blog_component_index_response)

          context "with no filter params" do
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :ok)
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

          it_behaves_like "paginated endpoint" do
            let(:create_resource) { -> { create(:component, manifest_name: "blogs", participatory_space: participatory_process) } }
            let(:each_resource) { ->(_resource, _index) {} }
            let(:resources) { Decidim::Component.all }
          end
        end
      end
    end
  end
end
