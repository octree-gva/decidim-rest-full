# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Spaces::SpacesController do
  Decidim.participatory_space_registry.manifests.map(&:name).each do |space_manifest|
    space_manifest_title = space_manifest.to_s.titleize
    path "/spaces/#{space_manifest}" do
      get "List #{space_manifest_title}" do
        tags "Spaces"
        produces "application/json"
        operationId "list#{space_manifest.to_s.camelize}"
        description "List participatory spaces of type #{space_manifest_title} for the current organization. Supports the same `filter` query parameters as `/spaces/search`, scoped to this space type. Extended data filter: `filter[extended_data_cont]` (requires `public.space.extended_data.read`)."
        it_behaves_like "localized params"
        it_behaves_like "paginated params"
        parameter name: :"filter[extended_data_cont]",
                  in: :query,
                  schema: { type: :string },
                  required: false,
                  description: "Search on space extended_data. See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data)."
        describe_api_endpoint(
          controller: Decidim::Api::RestFull::Spaces::SpacesController,
          action: :index,
          security_types: [:credentialFlow, :impersonationFlow],
          scopes: ["public"],
          permissions: ["public.space.read"]
        ) do
          before do
            skip "Initiative factory not available" if space_manifest == :initiatives && !FactoryBot.factories.registered?(:initiative)
            skip "Conference factory not available" if space_manifest == :conferences && !FactoryBot.factories.registered?(:conference)
            Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }.each do |manifest_name|
              create(:component, participatory_space: assembly, manifest_name:, published_at: Time.zone.now)
            end
          end

          let!(:participatory_process) { create(:participatory_process, organization:, title: { en: "My participatory_process for testing purpose", fr: "c'est une concertation" }) }
          let!(:assembly) { create(:assembly, organization:, title: { en: "My assembly for testing purpose", fr: "c'est une assemblée" }) }
          let!(:initiative) { space_manifest == :initiatives ? create(:initiative, organization:, title: { en: "My initiative for testing" }) : nil }
          let!(:conference) { space_manifest == :conferences ? create(:conference, organization:, title: { en: "My conference for testing" }) : nil }

          let(:id) do
            case space_manifest.to_s
            when "participatory_processes" then participatory_process.id
            when "initiatives" then initiative.id
            when "conferences" then conference.id
            else assembly.id
            end
          end

          let!(:space_list) do
            3.times do
              create(:assembly, organization:)
              create(:participatory_process, organization:)
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

          response "200", "#{space_manifest_title} list" do
            produces "application/json"
            schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:space_index_response)
            context "with a valid token" do
              let(:manifest_name) { space_manifest.to_s }
              let(:"locales[]") { %w(en fr) }
              let(:page) { 1 }
              let(:per_page) { 10 }

              run_test!(example_name: :ok) do |example|
                json_response = JSON.parse(example.body)
                expect(json_response["data"]).to be_an(Array)
                expect(json_response["data"].all? { |row| row["attributes"]["manifest_name"] == manifest_name }).to be(true)
                matching = json_response["data"].find { |row| row["id"] == id.to_s }
                expect(matching).to be_present
              end
            end

            if space_manifest.to_s == "participatory_processes"
              context "with filter[extended_data_cont] and permission" do
                let(:api_client) do
                  client = create(:api_client, organization:, scopes: %w(public))
                  client.permissions = [
                    client.permissions.build(permission: "public.space.read"),
                    client.permissions.build(permission: "public.space.extended_data.read")
                  ]
                  client.save!
                  client
                end
                let(:manifest_name) { space_manifest.to_s }
                let(:"filter[extended_data_cont]") { '"idx": "1"' }
                let(:page) { 1 }
                let(:per_page) { 50 }

                before do
                  participatory_process.extended_data.update!(data: { "idx" => "1" })
                end

                run_test!(example_name: :filter_by_extended_data) do |example|
                  data = JSON.parse(example.body)["data"]
                  expect(data.map { |d| d["id"] }).to include(participatory_process.id.to_s)
                end
              end

              context "with filter[extended_data_cont] no hit" do
                let(:api_client) do
                  client = create(:api_client, organization:, scopes: %w(public))
                  client.permissions = [
                    client.permissions.build(permission: "public.space.read"),
                    client.permissions.build(permission: "public.space.extended_data.read")
                  ]
                  client.save!
                  client
                end
                let(:manifest_name) { space_manifest.to_s }
                let(:"filter[extended_data_cont]") { '"idx": "missing"' }
                let(:page) { 1 }
                let(:per_page) { 50 }

                before do
                  participatory_process.extended_data.update!(data: { "idx" => "1" })
                end

                run_test!(example_name: :filter_by_extended_data_miss) do |example|
                  data = JSON.parse(example.body)["data"]
                  expect(data.map { |d| d["id"] }).not_to include(participatory_process.id.to_s)
                end
              end
            end

            it_behaves_like "localized endpoint"
          end

          if space_manifest.to_s == "participatory_processes"
            response "403", "Forbidden when filtering extended_data without permission" do
              produces "application/json"
              let(:manifest_name) { space_manifest.to_s }
              let(:"filter[extended_data_cont]") { '"idx": "1"' }
              let(:page) { 1 }
              let(:per_page) { 10 }

              before do
                participatory_process.extended_data.update!(data: { "idx" => "1" })
              end

              run_test!(example_name: :filter_extended_data_forbidden) do |example|
                expect(example.status).to eq(403)
              end
            end
          end
        end

        it_behaves_like "unauthorized when no Bearer token"
      end
    end
  end
end
