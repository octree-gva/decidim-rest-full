# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::ProposalComponentsController do
  path "/components/proposal_components/{id}" do
    get "Proposal Component Details" do
      tags "Components"
      produces "application/json"
      operationId "proposal_component"

      description "Find on proposal"
      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "filtered params", filter: "id", item_schema: { type: :integer }, only: :integer
      parameter name: "id", in: :path, schema: { type: :integer }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Components::ProposalComponentsController,
        action: :show,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["public"],
        permissions: ["public.component.read"]
      ) do
        let(:id) { component.id }

        let(:user) { create(:user, locale: "fr", organization: organization) }
        let(:component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let!(:assembly) { create(:assembly, organization: organization) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
        let!(:organization) { create(:organization) }
        it_behaves_like "localized endpoint"

        response "200", "Proposal Component" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_component_item_response)

          context "with no filter params" do
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :ok)
          end

          on_security(:impersonationFlow) do
            context "with an active draft" do
              let(:user) { create(:user, locale: "fr", organization: organization) }

              let!(:draft) do
                prop = create(:proposal, published_at: nil, component: component, users: [user])
                prop.update(rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: prop.id, api_client_id: api_client.id))
                prop
              end
              let(:bearer_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: draft.authors.first.id, application: api_client) }
              let(:Authorization) { "Bearer #{bearer_token.token}" }

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
        end
      end
    end
  end
end
