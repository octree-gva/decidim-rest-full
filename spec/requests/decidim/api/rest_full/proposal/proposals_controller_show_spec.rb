# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Proposal::ProposalsController, type: :request do
  path "/public/{space_manifest}/{space_id}/{component_id}/proposals/{proposal_id}" do
    get "Show a proposal detail" do
      tags "Proposals"
      produces "application/json"
      security [{ credentialFlowBearer: ["proposals"] }, { resourceOwnerFlowBearer: ["proposals"] }]
      operationId "proposal"
      description "Proposal detail"

      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: "space_manifest", in: :path, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }
      parameter name: "space_id", in: :path, schema: { type: :integer, description: "Space Id" }
      parameter name: "component_id", in: :path, schema: { type: :integer, description: "Component Id" }
      parameter name: "proposal_id", in: :path, schema: { type: :integer, description: "Proposal Id" }
      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
      let!(:proposal) { create(:proposal, component: proposal_component) }
      let(:"locales[]") { %w(en fr) }

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["proposals"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "proposals.read")
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

      response "200", "Proposal Found" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/proposal_response"

        context "when published" do
          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(proposal_id.to_s)
            expect(data["meta"]["published"]).to be_truthy
          end
        end

        context "when own drafts" do
          let!(:draft_proposal) do
            create(:proposal, component: proposal_component, published_at: nil, users: [user])
          end

          let(:proposal_id) { draft_proposal.id }

          run_test!(example_name: :ok_drafts) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data).to be_truthy
            expect(data["id"]).to eq(draft_proposal.id.to_s)
          end
        end
      end

      response "404", "Not Found" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with draft that did not co-authored" do
          let!(:draft_proposal) do
            proposal = create(:proposal, component: proposal_component, published_at: nil, users: [create(:user, :confirmed, organization: organization)])
            proposal.save!
            proposal
          end

          let(:proposal_id) { draft_proposal.id }

          run_test!(example_name: :not_found)
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

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
        schema "$ref" => "#/components/schemas/api_error"

        context "with no proposals scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals.read permission" do
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
          controller = Decidim::Api::RestFull::Proposal::ProposalsController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Proposal::ProposalsController).to receive(:new).and_return(controller)
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
