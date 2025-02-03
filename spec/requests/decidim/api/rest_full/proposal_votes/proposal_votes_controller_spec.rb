# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::ProposalVotes::ProposalVotesController, type: :request do
  path "/proposal_votes" do
    post "Vote" do
      tags "Proposals Vote"
      produces "application/json"
      security [{ credentialFlowBearer: ["proposals"] }, { resourceOwnerFlowBearer: ["proposals"] }]
      operationId "voteProposal"
      description "Vote on a proposal"

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          proposal_id:  { type: :integer, description: "Proposal Id" },
          data: {
            type: :object,
            properties: {
              weight: { type: :integer, description: "Weight for your vote" }
            },
            required: [ :weight],
            description: "Payload to send your vote"
          }
        }, required: [:data, :proposal_id]
      }

      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
      let!(:proposal_component) { create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process) }
      let!(:proposal) { create(:proposal, component: proposal_component) }
      let(:"locales[]") { %w(en fr) }
      let!(:body) do
        {
          data: { weight: 1} , proposal_id: proposal.id 
        }
      end

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["proposals"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "proposals.vote")
        ]
        api_client.save!
        api_client.reload
      end

      let(:user) { create(:user, locale: "fr", organization: organization) }

      # Routing
      let!(:impersonate_token) do
        create(:oauth_access_token, scopes: ["proposals"], resource_owner_id: user.id, application: api_client)
      end

      let(:Authorization) { "Bearer #{impersonate_token.token}" }
      let(:space_manifest) { "participatory_processes" }
      let(:space_id) { participatory_process.id }
      let(:component_id) { proposal_component.id }
      let(:proposal_id) { proposal.id }

      before do
        host! organization.host
      end

      response "200", "Vote created" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/proposal_response"

        context "when vote is active" do
          let!(:proposal) { create(:proposal, component: proposal_component) }

          run_test!(example_name: :default) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(proposal_id.to_s)
            expect(data["meta"]["published"]).to be_truthy
            expect(data["meta"]["voted"]).to eq({ "weight" => 1 })
          end
        end

        context "when vote is voting_cards" do
          let!(:proposal_component) do
            create(
              :proposal_component,
              :with_votes_enabled,
              participatory_space: participatory_process,
              settings: { awesome_voting_manifest: :voting_cards }
            )
          end
          let!(:proposal) { create(:proposal, component: proposal_component) }
          let!(:body) do
            {
              data: { weight: 2} , proposal_id: proposal.id 
            }
          end

          run_test!(example_name: :voting_cards) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(proposal_id.to_s)
            expect(data["meta"]["published"]).to be_truthy
            expect(data["meta"]["voted"]).to eq({ "weight" => 2 })
          end
        end

        context "when vote is voting_cards with abstention" do
          let!(:proposal_component) do
            create(
              :proposal_component,
              :with_votes_enabled,
              participatory_space: participatory_process,
              settings: { awesome_voting_manifest: :voting_cards, voting_cards_show_abstain: true }
            )
          end
          let!(:proposal) { create(:proposal, component: proposal_component) }
          let!(:body) do
            {
              data: { weight: 0} , proposal_id: proposal.id 
            }
          end

          run_test!(example_name: :voting_cards_with_abstention) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(proposal_id.to_s)
            expect(data["meta"]["published"]).to be_truthy
            expect(data["meta"]["voted"]).to eq({ "weight" => 0 })
          end
        end

        context "when vote is decidim default with abstention" do
          let!(:proposal_component) do
            create(
              :proposal_component,
              :with_votes_enabled,
              participatory_space: participatory_process,
              settings: { voting_cards_show_abstain: true }
            )
          end
          let!(:proposal) { create(:proposal, component: proposal_component) }
          let!(:body) do
            {
              data: { weight: 0} , proposal_id: proposal.id 
            }
          end

          run_test!(example_name: :default_with_abstention) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(proposal_id.to_s)
            expect(data["meta"]["published"]).to be_truthy
            expect(data["meta"]["voted"]).to eq({ "weight" => 0 })
          end
        end
      end

      response "404", "Not Found" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"
        context "when vote on draft" do
          let!(:draft_proposal) do
            proposal = create(:proposal, component: proposal_component, published_at: nil, users: [user])
            proposal.save!
            proposal
          end
          let!(:body) do
            {
              data: { weight: 1} , proposal_id: draft_proposal.id
            }
          end
          run_test!
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with client credentials" do
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: nil, application: api_client) }
          let!(:Authorization) { "Bearer #{impersonation_token.token}" }

          run_test!(example_name: :client_credentials)
        end

        context "when vote is disabled" do
          let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }

          run_test!(example_name: :vote_disabled)
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with no proposals scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: user.id, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals.vote permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["proposals"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client) }

          run_test! do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::ProposalVotes::ProposalVotesController.new
          allow(controller).to receive(:create).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::ProposalVotes::ProposalVotesController).to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
