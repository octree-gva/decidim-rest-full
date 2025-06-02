# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::ProposalVotes::ProposalVotesController do
  path "/proposal_votes" do
    post "Vote" do
      tags "Proposals Vote"
      produces "application/json"
      operationId "voteProposal"
      description "Vote on a proposal"

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        title: "Vote A Proposal Payload",
        properties: {
          proposal_id: { type: :integer, description: "Proposal Id" },
          data: {
            type: :object,
            title: "Vote A Proposal Data",
            properties: {
              weight: { type: :integer, description: "Weight for your vote" }
            },
            required: [:weight],
            description: "Payload to send your vote"
          }
        }, required: [:data, :proposal_id]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::ProposalVotes::ProposalVotesController,
        action: :create,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.vote"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
        let!(:proposal_component) { create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let(:"locales[]") { %w(en fr) }
        let!(:body) do
          {
            data: { weight: 1 }, proposal_id: proposal.id
          }
        end

        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }
        let(:component_id) { proposal_component.id }
        let(:proposal_id) { proposal.id }

        response "200", "Vote created" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_item_response)

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
                data: { weight: 2 }, proposal_id: proposal.id
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
                data: { weight: 0 }, proposal_id: proposal.id
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
                data: { weight: 0 }, proposal_id: proposal.id
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
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          context "when vote on draft" do
            let(:draft_proposal_author) { create(:user, locale: "fr", organization: organization) }
            let!(:draft_proposal) { create(:proposal, component: proposal_component, published_at: nil, users: [draft_proposal_author]) }
            let!(:body) do
              {
                data: { weight: 1 }, proposal_id: draft_proposal.id
              }
            end

            run_test!
          end
        end
      end
    end
  end
end
