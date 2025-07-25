# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Proposals::ProposalsController do
  path "/proposals/{id}" do
    get "Proposal Details" do
      tags "Proposals"
      produces "application/json"
      security [{ credentialFlowBearer: ["proposals"] }, { resourceOwnerFlowBearer: ["proposals"] }]
      operationId "proposal"
      description "Proposal detail"
      it_behaves_like "localized params"
      it_behaves_like "resource params"
      it_behaves_like "filtered params", filter: "voted_weight", item_schema: { type: :string }, only: :string
      it_behaves_like "filtered params", filter: "state", item_schema: { type: :string }, only: :string
      it_behaves_like "ordered params"

      parameter name: "id", in: :path, schema: { type: :integer, description: "Proposal Id" }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Proposals::ProposalsController,
        action: :show,
        security_types: [:credentialFlow, :impersonationFlow],
        scopes: ["proposals"],
        permissions: ["proposals.read"]
      ) do
        it_behaves_like "localized endpoint"
        let(:id) { proposal.id }
        let(:component_id) { proposal_component.id }
        let(:space_id) { participatory_process.id }
        let(:space_manifest) { "participatory_processes" }

        let(:"locales[]") { %w(en fr) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let!(:participatory_process) { create(:participatory_process, organization: organization) }

        response "200", "Proposal Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_item_response)

          context "when published" do
            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["id"]).to eq(id.to_s)
              expect(data["meta"]["published"]).to be_truthy
            end
          end

          context "when paginating" do
            context "when ordering by published_at DESC" do
              context "when selecting the last published proposal, next is the 2nd last published proposal, prev is nil" do
                let(:order) { "published_at" }
                let(:order_direction) { "desc" }
                let(:last_proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
                let!(:first_proposal) { create(:proposal, reference: "FIRST", component: last_proposal_component, published_at: 1.day.ago) }
                let!(:second_proposal) { create(:proposal, reference: "SECOND", component: last_proposal_component, published_at: 2.days.ago) }
                let!(:third_proposal) { create(:proposal, reference: "THIRD", component: last_proposal_component, published_at: 3.days.ago) }
                let(:"filter[state_not_eq]") { "rejected" }
                let(:component_id) { last_proposal_component.id }
                let(:id) { first_proposal.id }

                run_test! do |example|
                  data = JSON.parse(example.body)["data"]
                  expect(data["id"]).to eq(id.to_s)
                  expect(data["meta"]["published"]).to be_truthy
                  expect(data["links"]["next"]).to be_present
                  expect(data["links"]["next"]["meta"]["resource_id"]).to eq(second_proposal.id.to_s)
                  expect(data["links"]["prev"]).to be_nil
                end
              end

              context "when selecting the first published proposal, prev is the second published proposal, next is nil" do
                let(:order) { "published_at" }
                let(:order_direction) { "desc" }
                let(:last_proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
                let!(:first_proposal) { create(:proposal, reference: "FIRST", component: last_proposal_component, published_at: 1.day.ago) }
                let!(:second_proposal) { create(:proposal, reference: "SECOND", component: last_proposal_component, published_at: 2.days.ago) }
                let!(:third_proposal) { create(:proposal, reference: "THIRD", component: last_proposal_component, published_at: 3.days.ago) }
                let(:"filter[state_not_eq]") { "rejected" }
                let(:component_id) { last_proposal_component.id }
                let(:id) { third_proposal.id }

                run_test! do |example|
                  data = JSON.parse(example.body)["data"]
                  expect(data["id"]).to eq(id.to_s)
                  expect(data["meta"]["published"]).to be_truthy
                  expect(data["links"]["next"]).to be_nil
                  expect(data["links"]["prev"]).to be_present
                  expect(data["links"]["prev"]["meta"]["resource_id"]).to eq(second_proposal.id.to_s)
                end
              end
            end

            context "when looking for the next not-rejected proposal" do
              let!(:first_accepted_proposal) { create(:proposal, :accepted, component: proposal_component) }
              let!(:rejected_proposal) { create(:proposal, :rejected, component: proposal_component) }
              let!(:second_proposal) { create(:proposal, component: proposal_component) }
              let(:"filter[state_not_eq]") { "rejected" }
              let(:id) { first_accepted_proposal.id }

              run_test!(example_name: :navigation_non_rejected) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"]).to eq(id.to_s)
                expect(data["meta"]["published"]).to be_truthy
                expect(data["links"]["next"]).to be_present
                expect(data["links"]["next"]["meta"]["resource_id"]).to eq(second_proposal.id.to_s)
              end
            end

            context "when looking at the last accepted proposal" do
              let!(:first_accepted_proposal) { create(:proposal, :accepted, component: proposal_component) }
              let!(:second_accepted_proposal) { create(:proposal, :accepted, component: proposal_component) }
              let!(:rejected_proposal) { create(:proposal, :rejected, component: proposal_component) }
              let(:"filter[state_eq]") { "accepted" }
              let(:id) { second_accepted_proposal.id }

              run_test!(example_name: :navigation_last_accepted) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"]).to eq(id.to_s)
                expect(data["meta"]["published"]).to be_truthy
                expect(data["links"]["next"]).to be_nil
                expect(data["links"]["prev"]).to be_present
                expect(data["links"]["prev"]["meta"]["resource_id"]).to eq(first_accepted_proposal.id.to_s)
              end
            end
          end

          on_security(:impersonationFlow) do
            context "when own drafts" do
              let!(:draft_proposal) do
                create(:proposal, component: proposal_component, published_at: nil, users: [user])
              end

              let(:id) { draft_proposal.id }

              run_test!(example_name: :ok_drafts) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data).to be_truthy
                expect(data["id"]).to eq(draft_proposal.id.to_s)
              end
            end
          end

          context "when answered proposal" do
            let!(:accepted_proposal) { create(:proposal, :accepted, component: proposal_component) }

            context "when accepted" do
              let(:id) { accepted_proposal.id }

              run_test!(example_name: :accepted_proposal) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data).to be_truthy
                expect(data["id"]).to eq(accepted_proposal.id.to_s)
                expect(data["relationships"]["state"]["meta"]).to eq({ "token" => "accepted" })
                expect(data["relationships"]["state"]["data"]).to eq({ "id" => accepted_proposal.proposal_state.id.to_s, "type" => "proposal_state" })
              end
            end
          end
        end

        response "404", "Not Found" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          on_security(:impersonationFlow) do
            context "with draft that did not co-authored" do
              let!(:draft_proposal) do
                proposal = create(:proposal, component: proposal_component, published_at: nil, users: [create(:user, :confirmed, organization: organization)])
                proposal.save!
                proposal
              end

              let(:id) { draft_proposal.id }

              run_test!(example_name: :not_found)
            end
          end
        end
      end
    end
  end
end
