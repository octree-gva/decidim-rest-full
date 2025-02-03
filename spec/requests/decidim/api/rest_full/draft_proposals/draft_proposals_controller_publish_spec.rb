# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::DraftProposals::DraftProposalsController, type: :request do
  path "/draft_proposals/{id}/publish" do
    post "Publish a draft proposal" do
      tags "Draft Proposals"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["proposals"] }]
      operationId "publishDraftProposal"
      description "Publish a draft proposal"

      parameter name: "id", in: :path, schema: { type: :integer, description: "Draft Id" }, required: true

      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
      let!(:proposal) { create(:proposal, component: proposal_component) }

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["proposals"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "proposals.draft")
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
      let(:id) { proposal.id }

      def clean_drafts
        Decidim::Proposals::Proposal.where(
          decidim_component_id: component_id
        ).each(&:destroy)
      end

      before do
        host! organization.host
      end

      response "200", "Draft Proposal published" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/proposal_response"

        context "when all fields are valid" do
          let!(:proposal) do
            prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
            prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
            prop
          end
          let!(:Authorization) { "Bearer #{impersonate_token.token}" }
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
        schema "$ref" => "#/components/schemas/api_error"

        context "when body is invalid" do
          let!(:proposal) do
            prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
            prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
            prop
          end
          let(:id) { proposal.id }

          let!(:Authorization) { "Bearer #{impersonate_token.token}" }

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
        schema "$ref" => "#/components/schemas/api_error"

        context "with no draft" do
          before { clean_drafts }

          let(:id) { Decidim::Proposals::Proposal.last.id + 1 }

          run_test!(example_name: :not_found)
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with no proposals scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals.draft permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["proposals"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: nil, application: api_client) }

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
          controller = Decidim::Api::RestFull::DraftProposals::DraftProposalsController.new
          allow(controller).to receive(:publish).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::DraftProposals::DraftProposalsController).to receive(:new).and_return(controller)
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
