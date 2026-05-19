# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Attachments::AttachmentsController do
  path "/attachments/direct_upload" do
    post "Stage file for direct upload" do
      tags "Attachments"
      consumes "application/json"
      produces "application/json"
      operationId "attachmentsDirectUpload"
      parameter name: :filename, in: :query, type: :string, required: true
      parameter name: :byte_size, in: :query, type: :integer, required: true
      parameter name: :checksum, in: :query, type: :string, required: true
      parameter name: :content_type, in: :query, type: :string, required: false

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Attachments::AttachmentsController,
        action: :direct_upload,
        security_types: [:credentialFlow],
        scopes: ["attachments"],
        permissions: ["attachments.write"]
      ) do
        let(:filename) { "hello.pdf" }
        let(:byte_size) { 12_345 }
        let(:checksum) { Base64.strict_encode64(Digest::MD5.digest("x" * byte_size)) }
        let(:content_type) { "application/pdf" }

        response "201", "Direct upload prepared" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:attachment_direct_upload_response)
          run_test!(example_name: :ok) do |example|
            body = JSON.parse(example.body)
            expect(body["signed_id"]).to be_present
          end
        end
      end
    end
  end
end
