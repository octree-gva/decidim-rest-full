# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::DraftProposals::DraftProposalsController do
  path "/draft_proposals" do
    post "Create draft proposal" do
      tags "Draft Proposals"
      produces "application/json"
      security [{ resourceOwnerFlowBearer: ["proposals"] }]
      operationId "createDraftProposal"
      description <<~README
        Create a draft
      README

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              component_id: { type: :integer, description: "Component ID" }
            },
            required: [:component_id],
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

        context "when create empty" do
          before { clean_drafts }

          let(:body) { { data: { component_id: proposal_component.id } } }

          run_test!(example_name: :ok_empty) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["title"]["fr"]).to eq("")
            expect(data["meta"]["publishable"]).to be(false)
          end
        end
      end

      response "404", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with invalid component ID" do
          let(:body) { { data: { component_id: Decidim::Component.maximum(:id).to_i + 1 } } }

          after { clean_drafts }

          run_test!(:component_not_found)
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "when posted too much proposals" do
          let(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now, settings: { proposal_limit: 2 }) }
          let(:body) { { data: { title: "This is a valid title, but unfortunatly, I already posted too much stuff.", component_id: proposal_component.id } } }

          before do
            clean_drafts
            create(:proposal, component: proposal_component, published_at: Time.now.utc, users: [user])
            create(:proposal, component: proposal_component, published_at: Time.now.utc, users: [user])
          end

          run_test!(:bad_request_limit_reached) do |example|
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to include("you have exceeded the limit.")
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
        context "with client credentials" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample", component_id: proposal_component.id } } }

          after { clean_drafts }

          run_test!(example_name: :forbidden) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: user.id, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample", component_id: proposal_component.id } } }

          after { clean_drafts }

          run_test!(example_name: :forbidden_scope) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no proposals.draft permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["proposals"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: user.id, application: api_client) }
          let(:body) { { data: { title: "This is a valid proposal title sample", component_id: proposal_component.id } } }

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
          allow(controller).to receive(:create).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::DraftProposals::DraftProposalsController).to receive(:new).and_return(controller)
        end

        let(:body) { { data: { title: "This is a valid proposal title sample", component_id: proposal_component.id } } }

        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        run_test!(:server_error) do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
