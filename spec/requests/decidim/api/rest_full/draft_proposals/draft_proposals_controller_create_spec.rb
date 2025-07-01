# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::DraftProposals::DraftProposalsController do
  path "/draft_proposals" do
    post "Create draft proposal" do
      tags "Draft Proposals"
      produces "application/json"
      operationId "createDraftProposal"
      description <<~README
        Create a draft
      README

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        title: "Create Draft Proposal Payload",
        properties: {
          data: {
            type: :object,
            title: "Draft Proposal Data",
            properties: {
              component_id: { type: :integer, description: "Component ID" }
            },
            required: [:component_id],
            description: "Payload to update in the proposal"
          }
        }, required: [:data]
      }
      describe_api_endpoint(
        controller: Decidim::Api::RestFull::DraftProposals::DraftProposalsController,
        action: :create,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.draft"]
      ) do
        let!(:participatory_process) { create(:participatory_process, organization: organization) }
        let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let!(:proposal) do
          prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
          prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
          prop.body = nil
          prop.title = nil
          prop.save(validate: false)
          prop
        end
        let(:id) { proposal.id }
        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }
        let(:component_id) { proposal_component.id }

        response "200", "Draft updated" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:draft_proposal_item_response)

          context "when create empty" do
            before do
              Decidim::Proposals::Proposal.where(
                decidim_component_id: component_id
              ).each(&:destroy)
            end

            let(:body) { { data: { component_id: proposal_component.id } } }

            run_test!(example_name: :ok_empty) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["attributes"]["title"]["fr"]).to be_nil
              expect(data["meta"]["publishable"]).to be(false)
            end
          end
        end

        response "404", "Bad Request" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "with invalid component ID" do
            let(:body) { { data: { component_id: Decidim::Component.maximum(:id).to_i + 1 } } }

            after do
              Decidim::Proposals::Proposal.where(
                decidim_component_id: component_id
              ).each(&:destroy)
            end

            run_test!(:component_not_found)
          end
        end

        response "400", "Bad Request" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "when posted too much proposals" do
            let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now, settings: { proposal_limit: 2 }) }
            let(:body) { { data: { title: "This is a valid title, but unfortunatly, I already posted too much stuff.", component_id: proposal_component.id } } }

            before do
              Decidim::Proposals::Proposal.where(
                decidim_component_id: component_id
              ).each(&:destroy)
              create(:proposal, component: proposal_component, published_at: Time.now.utc, users: [user])
              create(:proposal, component: proposal_component, published_at: Time.now.utc, users: [user])
            end

            run_test!(:bad_request_limit_reached) do |example|
              error_description = JSON.parse(example.body)["error_description"]
              expect(error_description).to include("you have exceeded the limit.")
            end
          end
        end

        1
      end
    end
  end
end
