# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::VoteProposals::VoteProposalsController do
  path "/vote_proposals" do
    get "List vote proposals" do
      tags "Proposals"
      produces "application/json"
      operationId "listProposalVotes"
      description <<~README
        List `Decidim::Proposals::ProposalVote` rows for published proposals in visible spaces.

        ### Filters
        - `filter[creator_id]` (or `filter[author_id]`): voter user id
        - `filter[proposal_id]`: proposal id
        - `filter[component_id]`: proposals component id
        - `filter[participatory_space_id]`: participatory space id

        Responses support **conditional GET** (`ETag` / `If-None-Match`).

        ### Access
        Requires impersonation (`proposals.vote` or `proposals.read` for listing).
      README

      it_behaves_like "paginated params"
      it_behaves_like "filtered params", filter: "creator_id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered params", filter: "proposal_id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered params", filter: "component_id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered params", filter: "participatory_space_id", item_schema: { type: :integer }, only: :integer

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::VoteProposals::VoteProposalsController,
        action: :index,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.read"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let!(:vote) { create(:proposal_vote, proposal:, author: user, weight: 1) }

        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }

        response "200", "Votes listed" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:vote_proposals_index_response)

          run_test!(example_name: :ok) do |response|
            ids = JSON.parse(response.body)["data"].map { |r| r["id"] }
            expect(ids).to include(vote.id.to_s)
          end
        end
      end
    end

    post "Vote on a proposal (async)" do
      tags "Proposals"
      consumes "application/json"
      produces "application/json"
      operationId "castProposalVoteAsync"
      description <<~README
        Enqueue a vote on a **published** proposal. Poll `GET /jobs/:uuid` for the result (slim vote payload by default).

        Prefer this endpoint under load. Use `POST /vote_proposals/sync` when you need an immediate response.
      README

      parameter name: :body, in: :body, required: true, schema: {
        "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:vote_proposal_create_body)
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::VoteProposals::VoteProposalsController,
        action: :create,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.vote"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let!(:body) { { data: { weight: 1 }, proposal_id: proposal.id } }

        response "202", "Job accepted" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_accepted)

          run_test!(example_name: :accepted) do |response|
            expect(response).to have_http_status(:accepted)
            expect(JSON.parse(response.body)).to include("job_id")
          end
        end
      end
    end
  end

  path "/vote_proposals/sync" do
    post "Vote on a proposal (sync)" do
      tags "Proposals"
      consumes "application/json"
      produces "application/json"
      operationId "castProposalVote"
      description <<~README
        Cast a vote synchronously. Returns a **vote_proposal** resource by default.

        Set query `include_proposal=true` to return the full **proposal** payload (heavier).
      README

      parameter name: :body, in: :body, required: true, schema: {
        "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:vote_proposal_create_body)
      }
      parameter name: :include_proposal, in: :query, schema: { type: :boolean }, required: false,
                description: "When true, return the full proposal instead of the vote resource"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::VoteProposals::VoteProposalsController,
        action: :create_sync,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.vote"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let(:"locales[]") { %w(en fr) }
        let!(:body) { { data: { weight: 1 }, proposal_id: proposal.id } }

        response "400", "Bad Request when user already voted" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

          before { create(:proposal_vote, proposal:, author: user, weight: 1) }

          run_test!(example_name: :already_voted)
        end

        response "200", "Vote created" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:vote_proposal_item_response)

          run_test!(example_name: :default) do |response|
            data = JSON.parse(response.body)["data"]
            expect(data["type"]).to eq("vote_proposals")
            expect(data["attributes"]["weight"]).to eq(1)
          end
        end

        response "200", "Vote created with full proposal" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:proposal_item_response)

          let(:include_proposal) { true }

          run_test!(example_name: :with_proposal) do |response|
            data = JSON.parse(response.body)["data"]
            expect(data["id"]).to eq(proposal.id.to_s)
            expect(data["meta"]["voted"]).to eq({ "weight" => 1 })
          end
        end
      end
    end
  end

  path "/vote_proposals/{id}" do
    get "Show vote proposal" do
      tags "Proposals"
      produces "application/json"
      operationId "getProposalVote"
      description "Fetch a single vote by id. Conditional GET supported."

      parameter name: :id, in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::VoteProposals::VoteProposalsController,
        action: :show,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.read"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let!(:vote) { create(:proposal_vote, proposal:, author: user, weight: 1) }
        let(:id) { vote.id }

        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }

        response "200", "Vote found" do
          schema type: :object,
                 properties: {
                   data: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:vote_proposal) }
                 }

          run_test!(example_name: :ok)
        end
      end
    end

    delete "Remove vote on a proposal" do
      tags "Proposals"
      produces "application/json"
      operationId "deleteProposalVote"
      description "Remove the impersonated user's vote (`Decidim::Proposals::UnvoteProposal`). Returns the vote resource."

      parameter name: :id, in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::VoteProposals::VoteProposalsController,
        action: :destroy,
        security_types: [:impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.vote"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, :with_votes_enabled, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let!(:vote) { create(:proposal_vote, proposal:, author: user, weight: 1) }
        let(:id) { vote.id }

        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }

        response "200", "Vote removed" do
          run_test!(example_name: :ok) do
            expect(Decidim::Proposals::ProposalVote.exists?(vote.id)).to be(false)
          end
        end
      end
    end
  end
end
