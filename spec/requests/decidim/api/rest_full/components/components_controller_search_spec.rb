# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::ComponentsController do
  path "/components/search" do
    get "Search components" do
      tags "Components"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "searchComponents"
      description "List or search components of the organization"

      let(:Authorization) { "Bearer #{impersonation_token.token}" }
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
      let!(:api_client) do
        api_client = create(:api_client, scopes: ["public"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "public.component.read")
        ]
        api_client.save!
        api_client.reload
      end
      let(:component) { create(:component, participatory_space: participatory_process, manifest_name: "meetings", published_at: Time.zone.now) }
      let!(:assembly) { create(:assembly, organization: organization) }
      let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
      let!(:organization) { create(:organization) }

      before do
        host! organization.host
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

      it_behaves_like "paginated endpoint"
      it_behaves_like "localized endpoint"
      it_behaves_like "filtered endpoint", filter: "manifest_name", item_schema: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:component_manifest) }, only: :string
      it_behaves_like "filtered endpoint", filter: "id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered endpoint", filter: "participatory_space_id", item_schema: { type: :string }, only: :integer
      it_behaves_like "filtered endpoint", filter: "participatory_space_type", item_schema: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:space_type) }, only: :string
      it_behaves_like "filtered endpoint", filter: "name", item_schema: { type: :string }, only: :string

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

        context "with per_page=2, list max two components" do
          let(:page) { 1 }
          let(:per_page) { 2 }

          before do
            manifests = Decidim.participatory_space_registry.manifests.map(&:name)
            10.times.each do
              create(:component, participatory_space: assembly, manifest_name: manifests.sample, published_at: Time.zone.now)
            end
          end

          run_test!(example_name: :paginated) do |example|
            json_response = JSON.parse(example.body)
            expect(json_response["data"].size).to eq(per_page)
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

        context "with no public.component.read permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["public"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
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

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Components::ComponentsController.new
          allow(controller).to receive(:search).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Components::ComponentsController).to receive(:new).and_return(controller)
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
