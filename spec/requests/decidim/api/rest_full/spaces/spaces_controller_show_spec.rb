# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Spaces::SpacesController do
  Decidim.participatory_space_registry.manifests.map(&:name).each do |space_manifest|
    space_manifest_title = space_manifest.to_s.titleize
    path "/spaces/#{space_manifest}/{id}" do
      get "#{space_manifest_title} Details" do
        tags "Spaces"
        produces "application/json"
        security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
        operationId space_manifest.to_s.camelize.to_s
        description "Get detail of a #{space_manifest_title} given its id"
        let!(:component_list) do
          Array.new(3) do
            proposals = create(:component, participatory_space: assembly, manifest_name: "proposals", published_at: Time.zone.now)
            create(:proposal, component: proposals)
            create(:proposal, component: proposals)

            meeting = create(:component, participatory_space: assembly, manifest_name: "meetings", published_at: Time.zone.now)
            create(:meeting, component: meeting)
            create(:meeting, component: meeting)
            [meeting, proposals]
          end.flatten
        end
        let!(:space_list) do
          3.times do
            create(:assembly, organization: organization)
            create(:participatory_process, organization: organization)
          end
        end
        let!(:participatory_process) { create(:participatory_process, id: 6, organization: organization, title: { en: "My participatory_process for testing purpose", fr: "c'est une concertation" }) }
        let!(:assembly) { create(:assembly, id: 6, organization: organization, title: { en: "My assembly for testing purpose", fr: "c'est une assemblée" }) }
        let(:Authorization) { "Bearer #{impersonation_token.token}" }
        let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
        let!(:api_client) do
          api_client = create(:api_client, scopes: ["public"], organization: organization)
          api_client.permissions = [
            api_client.permissions.build(permission: "public.space.read")
          ]
          api_client.save!
          api_client.reload
        end
        let!(:organization) { create(:organization) }

        before do
          host! organization.host
          Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }.each do |manifest_name|
            create(:component, participatory_space: assembly, manifest_name: manifest_name, published_at: Time.zone.now)
          end
        end

        it_behaves_like "localized endpoint"
        parameter name: "id", in: :path, schema: { type: :integer, description: "Id of the space" }

        response "200", "#{space_manifest_title} Details" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:space_item_response)
          context "with a valid #{space_manifest} id" do
            let(:id) { "6" }
            let(:manifest_name) { space_manifest.to_s }

            run_test!(example_name: :ok) do |example|
              json_response = JSON.parse(example.body)
              expect(json_response["data"]["id"]).to eq("6")
            end
          end
        end

        response "403", "Forbidden" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          let(:id) { "6" }
          let(:manifest_name) { "participatory_processes" }

          context "with no public scope" do
            let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
            let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

            run_test!(example_name: :forbidden) do |_example|
              expect(response).to have_http_status(:forbidden)
              expect(response.body).to include("Forbidden")
            end
          end

          context "with no public.space.read permission" do
            let!(:api_client) { create(:api_client, organization: organization, scopes: ["public"]) }
            let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

            run_test! do |_example|
              expect(response).to have_http_status(:forbidden)
              expect(response.body).to include("Forbidden")
            end
          end
        end

        response "404", "Not found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
          context "with a valid assembly id" do
            let(:id) { "404" }

            run_test!(example_name: :not_found) do |example|
              JSON.parse(example.body)
              expect(example.status).to eq(404)
            end
          end
        end

        response "500", "Internal Server Error" do
          produces "application/json"
          let(:id) { "500" }

          before do
            controller = Decidim::Api::RestFull::Spaces::SpacesController.new
            allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
            allow(Decidim::Api::RestFull::Spaces::SpacesController).to receive(:new).and_return(controller)
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
end
