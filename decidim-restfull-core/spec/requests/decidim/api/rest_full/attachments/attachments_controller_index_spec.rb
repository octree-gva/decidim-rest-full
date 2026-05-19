# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Attachments::AttachmentsController do
  path "/attachments" do
    get "List attachments" do
      tags "Attachments"
      produces "application/json"
      operationId "listAttachments"
      it_behaves_like "paginated params"
      it_behaves_like "filtered params", filter: "attached_to_type", item_schema: { type: :string }, only: :string
      it_behaves_like "filtered params", filter: "attached_to_id", item_schema: { type: :integer }, only: :integer

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Attachments::AttachmentsController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["attachments"],
        permissions: ["attachments.read"]
      ) do
        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let!(:proposal) { create(:proposal, component:) }
        let!(:attachment) { create(:attachment, :with_pdf, attached_to: proposal) }

        response "200", "Attachments listed" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:attachment_index_response)

          let(:filter) { { attached_to_type: "Decidim::Proposals::Proposal", attached_to_id: proposal.id } }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.map { |d| d["id"] }).to include(attachment.id.to_s)
          end
        end
      end
    end
  end
end
