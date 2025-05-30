# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Proposals::ProposalsController do
  path "/proposals" do
    get "Proposals" do
      tags "Proposals"
      produces "application/json"
      operationId "proposals"
      description "Search proposals"
      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "resource params"
      it_behaves_like "ordered params", columns: %w(published_at rand)
      it_behaves_like "filtered params", filter: "voted_weight", item_schema: { type: :string }, only: :integer, security: [:impersonationFlow]
      it_behaves_like "filtered params", filter: "state", item_schema: { type: :string }, only: :string

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Proposals::ProposalsController,
        action: :index,
        security_types: [:credentialFlow, :impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.read"]
      ) do
        it_behaves_like "localized endpoint"
        let(:proposal_id) { proposal.id }
        let(:component_id) { proposal_component.id }
        let(:space_id) { participatory_process.id }
        let(:space_manifest) { "participatory_processes" }

        let(:"locales[]") { %w(en fr) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
        let!(:organization) { create(:organization) }
        let!(:per_page) { 50 }
        let!(:page) { 1 }

        response "200", "Proposal List" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_index_response)
          it_behaves_like "paginated endpoint" do
            let(:create_resource) { -> { create(:proposal, :accepted, component: proposal_component, published_at: 1.day.ago) } }
            let(:each_resource) { ->(_resource, _index) {} }
            let(:resources) { Decidim::Proposals::Proposal.all }
          end
          context "when voting_cards is enabled" do
            let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
            let(:proposal_component) do
              component = create(
                :proposal_component,
                :with_votes_enabled,
                participatory_space: participatory_process,
                settings: { awesome_voting_manifest: :voting_cards, voting_cards_show_abstain: true }
              )
              component
            end

            let!(:proposals) do
              create(:proposal, :accepted, component: proposal_component)
              create(:proposal, :rejected, component: proposal_component)
              create_list(:proposal, 5, component: proposal_component)
            end

            context "with filter state_eq accepted, filter only accepted proposal" do
              let(:"filter[state_eq]") { "accepted" }

              run_test!(example_name: :state_accepted) do |example|
                data = JSON.parse(example.body)["data"]
                data.each do |d|
                  expect(d["relationships"]["state"]["meta"]["token"]).to eq("accepted")
                end
                expect(data.size).to eq(1)
              end
            end

            context "with filter state_not_eq rejected, filter only non-rejected proposal" do
              let(:"filter[state_not_eq]") { "rejected" }

              run_test!(example_name: :state_non_rejected) do |example|
                data = JSON.parse(example.body)["data"]
                data.each do |d|
                  if d["relationships"]["state"]
                    expect(d["relationships"]["state"]["meta"]["token"]).not_to eq("rejected")
                  else
                    expect(d["relationships"]["state"]).to be_nil
                  end
                end
              end
            end
          end

          on_security(:impersonationFlow) do
            context "when voting_cards is enabled" do
              let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
              let(:proposal_component) do
                component = create(
                  :proposal_component,
                  :with_votes_enabled,
                  participatory_space: participatory_process,
                  settings: { awesome_voting_manifest: :voting_cards, voting_cards_show_abstain: true }
                )
                component
              end

              on_security(:credentialFlow) do
                before do
                  accepted_proposal = create(:proposal, :accepted, component: proposal_component)
                  create(:proposal_vote, proposal: accepted_proposal, author: user).update(weight: 1)
                  create(:proposal, :accepted, component: proposal_component)
                  create(:proposal, :rejected, component: proposal_component)
                  normal_proposal = create(:proposal, component: proposal_component)
                  liked_proposal = create(:proposal, component: proposal_component)
                  loved_proposal = create(:proposal, component: proposal_component)
                  create_list(:proposal, 5, component: proposal_component)
                  abstention_proposal = create(:proposal, component: proposal_component)
                  create(:proposal_vote, proposal: normal_proposal, author: user).update(weight: 1)
                  create(:proposal_vote, proposal: liked_proposal, author: user).update(weight: 1)
                  create(:proposal_vote, proposal: loved_proposal, author: user).update(weight: 2)
                  create(:proposal_vote, proposal: abstention_proposal, author: user).update(weight: 0)
                end

                context "with filter voted_weight" do
                  context "when filter voted_weight_eq 1, return nil" do
                    let(:"filter[voted_weight_eq]") { 1.to_s }

                    run_test!(example_name: :voted) do |example|
                      data = JSON.parse(example.body)["data"]
                      data.each do |d|
                        expect(d["meta"]["voted"]).to be_nil
                      end
                    end
                  end
                end
              end
              on_security(:impersonationFlow) do
                context "with filter voted_weight" do
                  context "when filter voted_weight_eq 1, filter only the vote_weight=1" do
                    let(:"filter[voted_weight_eq]") { 1.to_s }

                    run_test!(example_name: :voted) do |example|
                      data = JSON.parse(example.body)["data"]
                      data.each do |d|
                        expect(d["meta"]["voted"]).to eq({ "weight" => 1 })
                      end
                    end
                  end

                  context "when filter voted_weight_eq 0, filter only the abstention" do
                    let(:"filter[voted_weight_eq]") { 0.to_s }

                    run_test!(example_name: :abstentions) do |example|
                      data = JSON.parse(example.body)["data"]
                      data.each do |d|
                        expect(d["meta"]["voted"]).to eq({ "weight" => 0 })
                      end
                    end
                  end

                  context "when filter voted_weight_eq 1 and state_eq rejected, return an empty list" do
                    let(:"filter[state_eq]") { "rejected" }
                    let(:"filter[voted_weight_eq]") { 0.to_s }

                    run_test! do |example|
                      data = JSON.parse(example.body)["data"]
                      expect(data).to be_empty
                    end
                  end

                  context "when filter voted_weight_blank, filter only the non-voted proposals" do
                    let(:"filter[voted_weight_blank]") { true }

                    run_test!(example_name: :abstentions) do |example|
                      data = JSON.parse(example.body)["data"]
                      data.each do |d|
                        expect(d["meta"]).not_to have_key("voted")
                      end
                    end
                  end

                  context "when filter voted_weight_blank, and per_page=1, order=rand get one non-voted proposal" do
                    let(:"filter[voted_weight_blank]") { true }
                    let(:per_page) { 1 }
                    let(:order) { "rand" }

                    run_test!(example_name: :abstentions) do |example|
                      data = JSON.parse(example.body)["data"]
                      data.each do |d|
                        expect(d["meta"]["voted"]).to be_blank
                      end
                    end
                  end
                end
              end
            end
          end

          on_security(:impersonationFlow) do
            context "when list own drafts" do
              let!(:draft_proposal) do
                proposal = create(:proposal, component: proposal_component, published_at: nil, users: [user])
                proposal.save!
                proposal
              end

              let(:proposal_id) { draft_proposal.id }

              run_test!(example_name: :ok_drafts) do |example|
                data = JSON.parse(example.body)["data"]
                draft = data.find { |d| d["meta"]["published"] == false }
                expect(draft).to be_truthy
                expect(draft["id"]).to eq(draft_proposal.id.to_s)
              end
            end
          end
        end
      end
    end
  end
end
