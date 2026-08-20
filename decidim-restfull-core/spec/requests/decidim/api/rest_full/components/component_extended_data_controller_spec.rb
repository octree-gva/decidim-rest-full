# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Components::ComponentExtendedDataController do
  path "/components/{id}/extended_data" do
    get "Component extended data" do
      tags "Components"
      produces "application/json"
      operationId "getComponentExtendedData"
      description "See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data)."
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Components::ComponentExtendedDataController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["public"],
        permissions: ["public.component.read", "public.component.extended_data.read"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:component) { create(:component, participatory_space: participatory_process, published_at: Time.zone.now) }
        let(:id) { component.id }
        let(:object_path) { "." }

        response "200", "Extended data" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          before { component.extended_data.update!(data: { "a" => 1 }) }

          run_test!(example_name: :ok) do |example|
            expect(JSON.parse(example.body)["data"]).to include("a" => 1)
          end
        end
      end
    end
  end

  path "/components/{id}/extended_data/sync" do
    put "Set component extended data (sync)" do
      tags "Components"
      consumes "application/json"
      produces "application/json"
      operationId "setComponentExtendedData"
      description "See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data)."
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: { data: { type: :object, additionalProperties: true } },
        required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Components::ComponentExtendedDataController,
        action: :update_sync,
        security_types: [:credentialFlow],
        scopes: ["public"],
        permissions: ["public.component.read", "public.component.extended_data.update"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:component) { create(:component, participatory_space: participatory_process, published_at: Time.zone.now) }
        let(:id) { component.id }
        let(:object_path) { "." }
        let(:body) { { data: { "k" => "v" } } }

        response "200", "Updated" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          run_test!(example_name: :ok) do |_example|
            expect(component.reload.extended_data_hash).to include("k" => "v")
          end
        end
      end
    end
  end
end
