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
      let(:id) { proposal.id }
      let(:component_id) { proposal_component.id }
      let(:space_id) { participatory_process.id }
      let(:space_manifest) { "participatory_processes" }
      let(:Authorization) { "Bearer #{impersonate_token.token}" }
      # Routing
      let!(:impersonate_token) do
        create(:oauth_access_token, scopes: ["proposals"], resource_owner_id: user.id, application: api_client)
      end
      let(:user) { create(:user, locale: "fr", organization: organization) }
      let!(:api_client) do
        api_client = create(:api_client, scopes: ["proposals"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "proposals.read")
        ]
        api_client.save!
        api_client.reload
      end
      let(:"locales[]") { %w(en fr) }
      let!(:proposal) { create(:proposal, component: proposal_component) }
      let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:organization) { create(:organization) }

      before do
        host! organization.host
      end

      it_behaves_like "localized endpoint"
      it_behaves_like "resource endpoint"
      parameter name: "id", in: :path, schema: { type: :integer, description: "Proposal Id" }, required: true
      it_behaves_like "filtered endpoint", filter: "voted_weight", item_schema: { type: :string }, exclude_filters: %w(not_in not_eq lt gt start not_start matches does_not_match present)
      it_behaves_like "filtered endpoint", filter: "state", item_schema: { type: :string }, exclude_filters: %w(not_in lt gt start not_start matches does_not_match present)

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

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with no proposals scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals.read permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["proposals"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Proposals::ProposalsController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Proposals::ProposalsController).to receive(:new).and_return(controller)
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
