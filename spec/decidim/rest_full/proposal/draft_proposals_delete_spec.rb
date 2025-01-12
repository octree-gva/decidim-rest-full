# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Proposal::DraftProposalsController", type: :request do
  path "/public/{space_manifest}/{space_id}/{component_id}/proposals/draft" do
    delete "Withdrawn a draft proposal" do
      tags "Proposals"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["proposals"] }]
      operationId "withdrawnProposalDraft"
      description "Withdrawn a draft proposal. This action cannot be undone."

      parameter name: "space_manifest", in: :path, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }
      parameter name: "space_id", in: :path, schema: { type: :integer, description: "Space Id" }
      parameter name: "component_id", in: :path, schema: { type: :integer, description: "Component Id" }

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

      def clean_drafts
        Decidim::Proposals::Proposal.where(
          decidim_component_id: component_id
        ).each(&:destroy)
      end

      before do
        host! organization.host
      end

      response "200", "Draft proposal Removed" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/draft_proposal_response"

        context "when all fields were valid" do
          let!(:proposal) do
            prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
            prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
            prop
          end
          let!(:Authorization) { "Bearer #{impersonate_token.token}" }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(proposal.id.to_s)
          end
        end
      end

      response "404", "Not Found" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with no draft" do
          before { clean_drafts }

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
          controller = Decidim::Api::RestFull::Proposal::DraftProposalsController.new
          allow(controller).to receive(:destroy).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Proposal::DraftProposalsController).to receive(:new).and_return(controller)
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
