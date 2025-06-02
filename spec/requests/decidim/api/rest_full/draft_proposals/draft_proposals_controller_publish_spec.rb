# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::DraftProposals::DraftProposalsController do
  path "/draft_proposals/{id}/publish" do
    post "Publish a draft proposal" do
      tags "Draft Proposals"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["proposals"] }]
      operationId "publishDraftProposal"
      description "Publish a draft proposal"
      parameter name: "id", in: :path, schema: { type: :integer, description: "Draft Id" }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::DraftProposals::DraftProposalsController,
        action: :publish,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.draft"]
      ) do
        let!(:participatory_process) { create(:participatory_process, organization: organization) }
        let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let!(:proposal) { create(:proposal, component: proposal_component) }

        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }
        let(:component_id) { proposal_component.id }
        let(:id) { proposal.id }
        response "200", "Draft Proposal published" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_item_response)

          context "when all fields are valid" do
            let!(:proposal) do
              prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
              prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
              prop
            end
            let(:id) { proposal.id }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["id"]).to eq(proposal.id.to_s)
              expect(data["meta"]["published"]).to be_truthy
            end
          end
        end

        response "400", "Bad request" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "when body is invalid" do
            let!(:proposal) do
              prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
              prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
              prop
            end
            let(:id) { proposal.id }

            before do
              proposal.body = nil
              proposal.save(validate: false)
            end

            run_test!(example_name: :bad_request) do |_example|
              expect(response.body).to include("Body cannot be blank")
            end
          end
        end

        response "404", "Not Found" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "with no draft" do
            let(:id) { Decidim::Proposals::Proposal.maximum(:id).to_i + 1 }

            run_test!(example_name: :not_found)
          end
        end
      end
    end
  end
end
