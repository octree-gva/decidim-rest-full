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
        description "List participatory spaces of type #{space_manifest_title} for the current organization. Supports the same `filter` query parameters as `/spaces/search`, scoped to this space type."
        it_behaves_like "localized params"
        it_behaves_like "paginated params"
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

            it_behaves_like "localized endpoint"
          end
        end

        it_behaves_like "unauthorized when no Bearer token"
      end
    end
  end
end
