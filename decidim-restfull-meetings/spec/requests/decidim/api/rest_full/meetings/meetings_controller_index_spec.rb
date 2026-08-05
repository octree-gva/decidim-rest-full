# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Meetings::MeetingsController do
  path "/meetings" do
    get "Meetings" do
      tags "Meetings"
      produces "application/json"
      operationId "listMeetings"
      description <<~README
        List published meetings. Filter with `filter[extended_data_cont]` when the client has `meetings.extended_data.read`.

        See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
      README
      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "resource params"
      it_behaves_like "ordered params", columns: %w(start_time rand)
      parameter name: :"filter[extended_data_cont]",
                in: :query,
                schema: { type: :string },
                required: false,
                description: 'Search on meeting extended_data. Format: `"<key>":<space>"<value>"`'

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Meetings::MeetingsController,
        action: :index,
        security_types: [:credentialFlow, :impersonationFlow],
        scopes: ["meetings"],
        permissions: ["meetings.read"]
      ) do
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:meeting_component) { create(:meeting_component, participatory_space: participatory_process) }
        let!(:meeting) { create(:meeting, :published, component: meeting_component) }
        let(:component_id) { meeting_component.id }
        let(:space_id) { participatory_process.id }
        let(:space_manifest) { "participatory_processes" }
        let(:"locales[]") { %w(en) }
        let!(:per_page) { 50 }
        let!(:page) { 1 }

        response "200", "Meeting List" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:meeting_index_response)

          context "with no special filter" do
            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data).not_to be_empty
            end
          end

          context "with filter[extended_data_cont] and permission" do
            let(:api_client) do
              client = create(:api_client, organization:, scopes: %w(meetings))
              client.permissions = [
                client.permissions.build(permission: "meetings.read"),
                client.permissions.build(permission: "meetings.extended_data.read")
              ]
              client.save!
              client
            end
            let(:"filter[extended_data_cont]") { '"integration": "alpha"' }

            before do
              meeting.extended_data.update!(data: { "integration" => "alpha" })
              create(:meeting, :published, component: meeting_component)
            end

            run_test!(example_name: :filter_by_extended_data) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.size).to eq(1)
              expect(data.first["id"]).to eq(meeting.id.to_s)
            end
          end

          context "with filter[extended_data_cont] no hit" do
            let(:api_client) do
              client = create(:api_client, organization:, scopes: %w(meetings))
              client.permissions = [
                client.permissions.build(permission: "meetings.read"),
                client.permissions.build(permission: "meetings.extended_data.read")
              ]
              client.save!
              client
            end
            let(:"filter[extended_data_cont]") { '"integration": "missing"' }

            before do
              meeting.extended_data.update!(data: { "integration" => "alpha" })
            end

            run_test!(example_name: :filter_by_extended_data_miss) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data).to be_empty
            end
          end
        end

        response "403", "Forbidden when filtering extended_data without permission" do
          produces "application/json"
          let(:"filter[extended_data_cont]") { '"integration": "alpha"' }

          before do
            meeting.extended_data.update!(data: { "integration" => "alpha" })
          end

          run_test!(example_name: :filter_extended_data_forbidden) do |example|
            expect(example.status).to eq(403)
          end
        end
      end
    end
  end
end
