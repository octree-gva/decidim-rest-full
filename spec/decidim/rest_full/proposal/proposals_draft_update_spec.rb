# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Proposal::ProposalsController", type: :request do
  path "/public/{space_manifest}/{space_id}/{component_id}/proposals/draft" do
    put "Upsert a draft proposal" do
      tags "Proposals"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["proposals"] }]
      operationId "updateDraft"
      description "Update (or create) a draft proposal"

      parameter name: "space_manifest", in: :path, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }
      parameter name: "space_id", in: :path, schema: { type: :integer, description: "Space Id" }
      parameter name: "component_id", in: :path, schema: { type: :integer, description: "Component Id" }
      
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          data: { 
            type: :object, 
            properties: {
              title: {type: :string, description: "Title of the draft"},
              body: {type: :string, description: "Content of the draft"},
              locale: {type: :string, enum: Decidim.available_locales, description: "Locale of the draft. default to user locale"}
            },
            required: [],
            description: "Payload to update in the proposal" 
          },
        }, required: [:data]
      }
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

      before do
        host! organization.host
        Decidim::Proposals::Proposal.where(
          decidim_component_id: component_id,
        ).each(&:destroy)
      end

      response "200", "Draft updated" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/proposal_response"

        context "when update title" do
          let(:body) { {data: { title: "This is a valid proposal title sample" }} }
          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["title"]["fr"]).to eq("This is a valid proposal title sample")
            expect(data["meta"]["publishable"]).to be(false)
          end
        end

        context "when update body" do
          let(:text) { "I am quiet a valid proposal, with one sentence that is long enough to be valid I think." }
          let(:body) { {data: { body: text }} }
          run_test!do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["body"]["fr"]).to eq(text)
          end
        end

      end


      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with invalid title payload data" do
          let(:body) { {data: { title: "lol!" } } }

          run_test!(:bad_request_validation_title) do |example|
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to start_with("Title ")
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"
        context "with client credentials" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }
          let(:body) { {data: { title: "This is a valid proposal title sample" }} }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: user.id, application: api_client) }
          let(:body) { {data: { title: "This is a valid proposal title sample" }} }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals.draft permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["proposals"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client) }
          let(:body) { {data: { title: "This is a valid proposal title sample" }} }

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
          controller = Decidim::Api::RestFull::Proposal::ProposalsDraftsController.new
          allow(controller).to receive(:update).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Proposal::ProposalsDraftsController).to receive(:new).and_return(controller)
        end
        let(:body) { {data: { title: "This is a valid proposal title sample" }} }

        schema "$ref" => "#/components/schemas/api_error"

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
