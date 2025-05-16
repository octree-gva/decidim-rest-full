# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::DraftProposals::DraftProposalsController do
  path "/draft_proposals/{id}" do
    put "Update draft proposal" do
      tags "Draft Proposals"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["proposals"] }]
      operationId "updateDraftProposal"
      description <<~README
        This endpoint allows you to  update a draft proposal associated with your application ID.
        Drafts updated via this API are not visible in the Decidim front-end, and drafts created from the Decidim application are not editable through the API.
        Therefore, any draft you create here is new and tied to your application's credentials.

        ### Example Request

        ```http
        PUT /public/assemblies/12/2319/proposals/draft
        Content-Type: application/json
        Authorization: Bearer YOUR_IMPERSONATION_TOKEN

        {
          "title": "My valid title"
        }
        ```
        ## Access Requirements

        * Authentication: This endpoint requires an impersonation token. You must create drafts on behalf of a participant; drafts cannot be created using a service token (credential_token).

        ## Error Handling

        * Field Errors: Only errors related to the fields you're updating will be returned.
        * Publishable Status: To determine if the draft is publishable, check the data.meta.publishable field in the response.

        ### Example response
        ```json
        {
          "data": {
            "id": "12345",
            "type": "proposal",
            "attributes": {
              "title": "My valid title",
              "body": null
            },
            "meta": {
              "publishable": false
            }
          }
        }
        ```
        In this example, the title is valid, so the server returns a 200 OK status.
        However, since the body is blank, meta.publishable is false, indicating that the draft is not yet ready for publication.
      README

      parameter name: "id", in: :path, schema: { type: :integer, description: "Draft Id" }, required: true

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              title: { type: :string, description: "Title of the draft" },
              body: { type: :string, description: "Content of the draft" },
              locale: { type: :string, enum: Decidim.available_locales, description: "Locale of the draft. default to user locale" }
            },
            description: "Payload to update in the proposal"
          }
        }, required: [:data]
      }
      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
      let!(:proposal) do
        prop = create(:proposal, published_at: nil, component: proposal_component, users: [user])
        prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
        prop.body = nil
        prop.title = nil
        prop.save(validate: false)
        prop
      end
      let(:id) { proposal.id }
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

      response "200", "Draft updated" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:draft_proposal_item_response)

        context "when update title" do
          let(:body) { { data: { title: "This is a valid proposal title sample" } } }

          after { clean_drafts }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["title"]["fr"]).to eq("This is a valid proposal title sample")
            expect(data["meta"]["publishable"]).to be(false)
          end
        end

        context "when update nothing" do
          let(:body) { { data: {} } }
          let(:id) { proposal.id }

          after { clean_drafts }

          run_test!(example_name: :ok_empty) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["title"]["fr"]).to eq("")
            expect(data["meta"]["publishable"]).to be(false)
          end
        end

        context "when update body" do
          let(:text) { "I am quiet a valid proposal, with one sentence that is long enough to be valid I think." }
          let(:body) { { data: { body: text } } }
          let(:id) { proposal.id }

          after { clean_drafts }

          run_test!(:ok_update_body) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["body"]["fr"]).to eq(text)
          end
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with invalid title payload data" do
          let(:body) { { data: { title: "lol!" } } }

          after { clean_drafts }

          run_test!(:bad_request_validation_title) do |example|
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to start_with("Title ")
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
        context "with client credentials" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample" } } }

          after { clean_drafts }

          run_test!(example_name: :forbidden) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: user.id, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample" } } }

          after { clean_drafts }

          run_test!(example_name: :forbidden_scope) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals.draft permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["proposals"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample" } } }

          after { clean_drafts }

          run_test! do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"
        after { clean_drafts }

        before do
          controller = Decidim::Api::RestFull::DraftProposals::DraftProposalsController.new
          allow(controller).to receive(:update).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::DraftProposals::DraftProposalsController).to receive(:new).and_return(controller)
        end

        let(:body) { { data: { title: "This is a valid proposal title sample" } } }

        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        run_test!(:server_error) do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
