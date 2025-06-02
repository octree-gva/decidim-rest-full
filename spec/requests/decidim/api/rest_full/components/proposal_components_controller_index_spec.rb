# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::ProposalComponentsController do
  path "/components/proposal_components" do
    get "Proposal Components" do
      tags "Components"
      produces "application/json"
      operationId "proposal_components"
      description "List or search proposal components of the organization"
      it_behaves_like "filtered params", filter: "name", item_schema: { type: :string }, only: :string
      it_behaves_like "filtered params", filter: "participatory_space_type", item_schema: { type: :string, example: "Decidim::Assembly" }, only: :string
      it_behaves_like "filtered params", filter: "participatory_space_id", item_schema: { type: :string }, only: :integer
      it_behaves_like "paginated params"
      it_behaves_like "localized params"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Components::ProposalComponentsController,
        action: :index,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["public"],
        permissions: ["public.component.read"]
      ) do
        let(:user) { create(:user, locale: "fr", organization: organization) }
        let(:component) { create(:proposal_component) }
        let!(:assembly) { create(:assembly, organization: organization) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
        let!(:organization) { create(:organization) }

        before do
          proposals = create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now)
          create(:proposal, component: proposals)
          create(:proposal, component: proposals)
          create(:proposal, component: proposals, state: "accepted")

          create(
            :proposal_component,
            :with_votes_enabled,
            participatory_space: participatory_process,
            settings: { awesome_voting_manifest: :voting_cards }
          )
        end

        it_behaves_like "localized endpoint"

        response "200", "List of proposal components" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_component_index_response)

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

          context "with impersonation and an active draft" do
            let!(:bearer_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: user.id, application: api_client) }
            let(:Authorization) { "Bearer #{bearer_token.token}" }
            let!(:draft) do
              proposal_component = create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now)
              prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
              prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
              prop
            end

            run_test!(example_name: :ok_with_draft) do |example|
              json_response = JSON.parse(example.body)
              comp = json_response["data"].find { |d| d["id"] == draft.decidim_component_id.to_s }
              expect(comp["links"]["draft"]).to be_present
              expect(comp["links"]["draft"]["meta"]).to eq(
                {
                  "component_id" => draft.decidim_component_id.to_s,
                  "component_manifest" => "proposals",
                  "space_id" => draft.component.participatory_space_id.to_s,
                  "space_manifest" => "participatory_processes",
                  "resource_id" => draft.id.to_s,
                  "action_method" => "GET"
                }
              )
            end
          end

          it_behaves_like "paginated endpoint" do
            let(:create_resource) { -> { create(:component, participatory_space: assembly, manifest_name: "proposals", published_at: Time.zone.now) } }
            let(:each_resource) { ->(_resource, _index) {} }
            let(:resources) { Decidim::Component.all }
          end
        end
      end
    end
  end
end
