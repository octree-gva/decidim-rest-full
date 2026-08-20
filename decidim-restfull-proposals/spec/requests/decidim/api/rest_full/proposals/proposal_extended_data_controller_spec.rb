# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Proposals::ProposalExtendedDataController do
  path "/proposals/{id}/extended_data" do
    get "Proposal extended data" do
      tags "Proposals"
      produces "application/json"
      operationId "getProposalExtendedData"
      description "See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data)."
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Proposals::ProposalExtendedDataController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["proposals"],
        permissions: ["proposals.read", "proposals.extended_data.read"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let(:id) { proposal.id }
        let(:object_path) { "." }

        response "200", "Extended data" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          before { proposal.extended_data.update!(data: { "source" => "api" }) }

          run_test!(example_name: :ok) do |example|
            expect(JSON.parse(example.body)["data"]).to include("source" => "api")
          end
        end
      end
    end
  end

  path "/proposals/{id}/extended_data/sync" do
    put "Set proposal extended data (sync)" do
      tags "Proposals"
      consumes "application/json"
      produces "application/json"
      operationId "setProposalExtendedData"
      description "See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data)."
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: { data: { type: :object, additionalProperties: true } },
        required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Proposals::ProposalExtendedDataController,
        action: :update_sync,
        security_types: [:credentialFlow],
        scopes: ["proposals"],
        permissions: ["proposals.read", "proposals.extended_data.update"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let(:id) { proposal.id }
        let(:object_path) { "." }
        let(:body) { { data: { "source" => "sync" } } }

        response "200", "Updated" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          run_test!(example_name: :ok) do |_example|
            expect(proposal.reload.extended_data_hash).to include("source" => "sync")
          end
        end
      end
    end
  end
end
