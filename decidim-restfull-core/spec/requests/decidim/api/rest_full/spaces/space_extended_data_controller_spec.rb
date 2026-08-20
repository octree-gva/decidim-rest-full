# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Spaces::SpaceExtendedDataController do
  path "/spaces/participatory_processes/{id}/extended_data" do
    get "Space extended data" do
      tags "Spaces"
      produces "application/json"
      operationId "getSpaceExtendedData"
      description "See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data)."
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Spaces::SpaceExtendedDataController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["public"],
        permissions: ["public.space.read", "public.space.extended_data.read"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let(:id) { participatory_process.id }
        let(:object_path) { "." }
        let(:manifest_name) { "participatory_processes" }

        response "200", "Extended data" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          before { participatory_process.extended_data.update!(data: { "zone" => "north" }) }

          run_test!(example_name: :ok) do |example|
            expect(JSON.parse(example.body)["data"]).to include("zone" => "north")
          end
        end
      end
    end
  end

  path "/spaces/participatory_processes/{id}/extended_data/sync" do
    put "Set space extended data (sync)" do
      tags "Spaces"
      consumes "application/json"
      produces "application/json"
      operationId "setSpaceExtendedData"
      description "See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data)."
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: { data: { type: :object, additionalProperties: true } },
        required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Spaces::SpaceExtendedDataController,
        action: :update_sync,
        security_types: [:credentialFlow],
        scopes: ["public"],
        permissions: ["public.space.read", "public.space.extended_data.update"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let(:id) { participatory_process.id }
        let(:object_path) { "." }
        let(:manifest_name) { "participatory_processes" }
        let(:body) { { data: { "zone" => "south" } } }

        response "200", "Updated" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          run_test!(example_name: :ok) do |_example|
            expect(participatory_process.reload.extended_data_hash).to include("zone" => "south")
          end
        end
      end
    end
  end
end
