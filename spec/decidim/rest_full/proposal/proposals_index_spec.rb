# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Proposal::ProposalsController", type: :request do
  path "/public/{space_manifest}/{space_id}/{component_id}/proposals" do
    get "Show proposal list" do
      tags "Proposals"
      produces "application/json"
      security [{ credentialFlowBearer: ["proposals"] }, { resourceOwnerFlowBearer: ["proposals"] }]
      operationId "proposals"
      description "Proposals list"

      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
      parameter name: :order, in: :query, schema: { type: :string, description: "field to order by", enum: %w(published_at rand) }, required: false
      parameter name: :order_direction, in: :query, schema: { type: :string, description: "order direction", enum: %w(desc asc) }, required: false

      parameter name: "space_manifest", in: :path, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }
      parameter name: "space_id", in: :path, schema: { type: :integer, description: "Space Id" }
      parameter name: "component_id", in: :path, schema: { type: :integer, description: "Component Id" }
      let!(:page) { 1 }
      let!(:per_page) { 50 }
      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
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
        schema "$ref" => "#/components/schemas/proposals_response"
        context "when ordered" do
          before do
            [
              create(:proposal, component: proposal_component, users: [create(:user, :confirmed, organization: organization)]),
              create(:proposal, component: proposal_component, users: [create(:user, :confirmed, organization: organization)]),
              create(:proposal, component: proposal_component, users: [create(:user, :confirmed, organization: organization)])
            ].each_with_index do |proposal, index|
              proposal.published_at = (index + 1).minutes.ago
              proposal.save!
              proposal
            end
          end

          let!(:impersonate_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: nil, application: api_client) }

          context "with published_at asc (default)" do
            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              proposals = Decidim::Proposals::Proposal.where(component: proposal_component).order(published_at: :asc).ids
              expect(data.first["id"]).to eq(proposals.first.to_s)
              expect(data.last["id"]).to eq(proposals.last.to_s)
            end
          end

          context "with published_at desc" do
            let(:order_direction) { "desc" }

            run_test! do |example|
              data = JSON.parse(example.body)["data"]
              proposals = Decidim::Proposals::Proposal.where(component: proposal_component).order(published_at: :asc).ids
              expect(data.first["id"]).to eq(proposals.last.to_s)
              expect(data.last["id"]).to eq(proposals.first.to_s)
            end
          end

          context "with rand" do
            let(:order) { "rand" }

            run_test!
          end
        end

        context "with per_page=2, list max two proposals" do
          let(:page) { 1 }
          let(:per_page) { 2 }
          let!(:impersonate_token) { create(:oauth_access_token, scopes: "proposals", resource_owner_id: nil, application: api_client) }
          let!(:proposals) do
            [
              create(:proposal, component: proposal_component, users: [create(:user, :confirmed, organization: organization)]),
              create(:proposal, component: proposal_component, users: [create(:user, :confirmed, organization: organization)]),
              create(:proposal, component: proposal_component, users: [create(:user, :confirmed, organization: organization)])
            ].each_with_index do |proposal, index|
              proposal.published_at = (index + 1).minutes.ago
              proposal.save!
              proposal
            end
          end

          run_test!(example_name: :paginated) do |example|
            json_response = JSON.parse(example.body)
            expect(json_response["data"].size).to eq(per_page)
          end
        end

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
          allow(controller).to receive(:index).and_raise(StandardError.new("Intentional error for testing"))
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
