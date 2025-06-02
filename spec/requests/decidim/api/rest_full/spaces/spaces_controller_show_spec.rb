# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Spaces::SpacesController do
  Decidim.participatory_space_registry.manifests.map(&:name).each do |space_manifest|
    space_manifest_title = space_manifest.to_s.titleize
    path "/spaces/#{space_manifest}/{id}" do
      get "#{space_manifest_title} Details" do
        tags "Spaces"
        produces "application/json"
        operationId space_manifest.to_s.camelize.to_s
        description "Get detail of a #{space_manifest_title} given its id"
        it_behaves_like "localized params"
        parameter name: "id", in: :path, schema: { type: :integer, description: "Id of the space" }

        describe_api_endpoint(
          controller: Decidim::Api::RestFull::Spaces::SpacesController,
          action: :show,
          security_types: [:credentialFlow, :impersonationFlow],
          scopes: ["public"],
          permissions: ["public.space.read"]
        ) do
          let!(:participatory_process) { create(:participatory_process, id: 6, organization: organization, title: { en: "My participatory_process for testing purpose", fr: "c'est une concertation" }) }
          let!(:assembly) { create(:assembly, id: 6, organization: organization, title: { en: "My assembly for testing purpose", fr: "c'est une assemblée" }) }
          let(:id) { assembly.id }

          let!(:space_list) do
            3.times do
              create(:assembly, organization: organization)
              create(:participatory_process, organization: organization)
            end
          end

          let!(:component_list) do
            Array.new(3) do
              proposals = create(:component, participatory_space: assembly, manifest_name: "proposals", published_at: Time.zone.now)
              create(:proposal, component: proposals)
              create(:proposal, :accepted, component: proposals)
              create(:proposal, :rejected, component: proposals)

              meeting = create(:component, participatory_space: assembly, manifest_name: "meetings", published_at: Time.zone.now)
              create(:meeting, component: meeting)
              create(:meeting, component: meeting)
              [meeting, proposals]
            end.flatten
          end

          before do
            Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }.each do |manifest_name|
              create(:component, participatory_space: assembly, manifest_name: manifest_name, published_at: Time.zone.now)
            end
          end

          response "200", "#{space_manifest_title} Details" do
            produces "application/json"
            schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:space_item_response)
            context "with a valid #{space_manifest} id" do
              let(:manifest_name) { space_manifest.to_s }

              run_test!(example_name: :ok) do |example|
                json_response = JSON.parse(example.body)
                expect(json_response["data"]["id"]).to eq(assembly.id.to_s)
              end
            end

            it_behaves_like "localized endpoint"
          end

          response "404", "Not found" do
            produces "application/json"
            schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)
            context "with a valid #{space_manifest_title} id" do
              let(:id) { "404" }

              run_test!(example_name: :not_found) do |example|
                JSON.parse(example.body)
                expect(example.status).to eq(404)
              end
            end
          end
        end
      end
    end
  end
end
