# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Attachments::AttachmentsController do
  path "/attachments/{id}" do
    get "Show attachment" do
      tags "Attachments"
      produces "application/json"
      operationId "showAttachment"
      parameter name: :id, in: :path, type: :string, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Attachments::AttachmentsController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["attachments"],
        permissions: ["attachments.read"]
      ) do
        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
        let!(:proposal) { create(:proposal, component:) }
        let!(:attachment) { create(:attachment, :with_pdf, attached_to: proposal) }
        let(:id) { attachment.id }

        response "200", "Attachment found" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:attachment_item_response)
          run_test!(example_name: :ok)
        end
      end
    end
  end
end
