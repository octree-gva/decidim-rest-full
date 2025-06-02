# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::DraftProposals::DraftProposalsController do
  path "/draft_proposals/{id}" do
    delete "Withdrawn a draft proposal" do
      tags "Draft Proposals"
      produces "application/json"
      operationId "withdrawnDraftProposal"
      description "Withdrawn a draft proposal. This action cannot be undone."
      parameter name: "id", in: :path, schema: { type: :integer, description: "Draft Id" }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::DraftProposals::DraftProposalsController,
        action: :destroy,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.draft"]
      ) do
        let!(:organization) { create(:organization) }
        let!(:participatory_process) { create(:participatory_process, organization: organization) }
        let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }
        let(:component_id) { proposal_component.id }
        let!(:proposal) do
          create(:proposal, published_at: nil, component: proposal_component, users: [user])
        end
        let(:id) { proposal.id }

        response "200", "Draft proposal Removed" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:draft_proposal_item_response)

          context "when all fields were valid" do
            let!(:proposal) do
              prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
              prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
              prop
            end
            let(:id) { proposal.id }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["id"]).to eq(proposal.id.to_s)
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
