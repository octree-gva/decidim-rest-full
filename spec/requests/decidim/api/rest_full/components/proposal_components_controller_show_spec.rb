# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::ProposalComponentsController do
  path "/components/proposal_components/{id}" do
    get "Proposal Component Details" do
      tags "Components"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "proposal_component"

      description "Find on proposal"
      let(:id) { component.id }
      let(:Authorization) { "Bearer #{impersonation_token.token}" }
      let(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
      let!(:api_client) do
        api_client = create(:api_client, scopes: ["public"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "public.component.read")
        ]
        api_client.save!
        api_client.reload
      end
      let(:user) { create(:user, locale: "fr", organization: organization) }
      let(:component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
      let!(:assembly) { create(:assembly, organization: organization) }
      let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
      let!(:organization) { create(:organization) }

      before do
        host! organization.host
      end

      it_behaves_like "localized endpoint"
      it_behaves_like "paginated endpoint"
      parameter name: "id", in: :path, schema: { type: :integer }
      it_behaves_like "filtered endpoint", filter: "id", item_schema: { type: :integer }, exclude_filters: %w(not_in not_eq lt gt start not_start matches does_not_match present blank)

      response "200", "Proposal Component" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_component_item_response)

        context "with no filter params" do
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :ok)
        end

        context "with impersonation and an active draft" do
          let(:user) { create(:user, locale: "fr", organization: organization) }

          let!(:draft) do
            prop = create(:proposal, published_at: nil, component: component, users: [user])
            prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
            prop
          end
          let(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: draft.authors.first.id, application: api_client) }
          let(:Authorization) { "Bearer #{impersonation_token.token}" }

          run_test!(example_name: :ok_with_draft) do |example|
            json_response = JSON.parse(example.body)
            comp = json_response["data"]
            expect(comp["links"]["draft"]).to be_present
            expect(comp["links"]["draft"]["meta"]).to eq(
              {
                "component_id" => draft.decidim_component_id.to_s,
                "component_manifest" => "proposals",
                "space_id" => draft.component.participatory_space_id.to_s,
                "space_manifest" => "participatory_processes",
                "resource_id" => draft.id.to_s,
                "action_method" => "GET"
              }
            )
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with no public scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no public.component.read permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["public"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
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

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Components::ProposalComponentsController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Components::ProposalComponentsController).to receive(:new).and_return(controller)
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
