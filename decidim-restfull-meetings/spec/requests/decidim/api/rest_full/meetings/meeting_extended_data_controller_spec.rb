# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Meetings::MeetingExtendedDataController do
  path "/meetings/{id}/extended_data" do
    get "Meeting extended data" do
      tags "Meetings"
      produces "application/json"
      operationId "getMeetingExtendedData"
      description <<~README
        Fetch meeting extended data at `object_path`. See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
      README
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Meetings::MeetingExtendedDataController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["meetings"],
        permissions: ["meetings.read", "meetings.extended_data.read"]
      ) do
        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:meeting_component) { create(:meeting_component, participatory_space: participatory_process) }
        let!(:meeting) { create(:meeting, :published, component: meeting_component) }
        let(:id) { meeting.id }
        let(:object_path) { "." }

        response "200", "Extended data" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          before do
            meeting.extended_data.update!(data: { "foo" => { "bar" => "true" } })
          end

          run_test!(example_name: :ok) do |example|
            body = JSON.parse(example.body)
            expect(body["data"]).to include("foo" => { "bar" => "true" })
          end
        end
      end
    end
  end

  path "/meetings/{id}/extended_data/sync" do
    put "Set meeting extended data (sync)" do
      tags "Meetings"
      consumes "application/json"
      produces "application/json"
      operationId "setMeetingExtendedData"
      description <<~README
        Merge meeting extended data at `object_path`. See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
      README
      parameter name: "object_path", in: :query, required: true, schema: { type: :string }
      parameter name: "id", in: :path, schema: { type: :string }
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: { data: { type: :object, additionalProperties: true } },
        required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Meetings::MeetingExtendedDataController,
        action: :update_sync,
        security_types: [:credentialFlow],
        scopes: ["meetings"],
        permissions: ["meetings.read", "meetings.extended_data.update"]
      ) do
        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:meeting_component) { create(:meeting_component, participatory_space: participatory_process) }
        let!(:meeting) { create(:meeting, :published, component: meeting_component) }
        let(:id) { meeting.id }
        let(:object_path) { "." }
        let(:body) { { data: { "hello" => "world" } } }

        response "200", "Updated" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:resource_extended_data)

          run_test!(example_name: :ok) do |example|
            expect(JSON.parse(example.body)["data"]).to include("hello" => "world")
            expect(meeting.reload.extended_data_hash).to include("hello" => "world")
          end
        end
      end
    end
  end
end
