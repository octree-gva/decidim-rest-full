# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Public::ComponentsController", type: :request do
  path "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/public/components" do
    get "List Components" do
      tags "Public"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      Api::Definitions::FILTER_PARAM.call(
        "manifest_name",
        { type: :string, enum: Decidim.component_registry.manifests.map { |manifest| manifest.name.to_s }.reject { |manifest_name| manifest_name == "dummy" } },
        %w(lt gt start not_start matches does_not_match present blank)
      ).each do |param|
        parameter(**param)
      end
      Api::Definitions::FILTER_PARAM.call(
        "participatory_space_id",
        { type: :string },
        %w(not_in not_eq lt gt start not_start matches does_not_match present blank)
      ).each do |param|
        parameter(**param)
      end
      Api::Definitions::FILTER_PARAM.call(
        "participatory_space_type",
        { type: :string, example: "Decidim::Assembly" },
        %w(not_in not_eq lt gt start not_start matches does_not_match present blank)
      ).each do |param|
        parameter(**param)
      end
      Api::Definitions::FILTER_PARAM.call(
        "name",
        { type: :string },
        %w(not_in in lt gt not_start does_not_match present blank)
      ).each do |param|
        parameter(**param)
      end
      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false
      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:assembly) { create(:assembly, organization: organization) }
      let(:component) { create(:component, participatory_space: participatory_process, manifest_name: "meetings", published_at: Time.zone.now) }

      let!(:api_client) { create(:api_client, organization: organization) }
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
      let(:Authorization) { "Bearer #{impersonation_token.token}" }

      before do
        host! organization.host
        create(:meeting, component: component)
        create(:meeting, component: component)

        proposals = create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now)
        create(:proposal, component: proposals)
        create(:proposal, component: proposals)

        accountabilities = create(:accountability_component, participatory_space: participatory_process, published_at: Time.zone.now)
        create(:result, component: accountabilities)
        create(:result, component: accountabilities)
      end

      response "200", "List of components" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/components_response"

        context "with no filter params" do
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :ok)
        end

        context "with filter[manifest_name_in][] filter" do
          let(:"filter[manifest_name_in][]") { %w(meetings) }
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :manifest_name_in_Meetings) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data).to eq(data.select { |resp| resp["attributes"]["manifest_name"] == "meetings" })
            expect(data).to eq(data.select { |resp| resp["type"] == "meeting_component" })
          end
        end

        context "with filter[participatory_space_type_eq]=Decidim::ParticipatoryProcess and filter[participatory_space_type_id_eq]=processId filters" do
          let(:"filter[participatory_space_id_eq]") { participatory_process.id.to_s }
          let(:"filter[participatory_space_type_eq]") { "Decidim::ParticipatoryProcess" }
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :components_in_Process) do |example|
            data = JSON.parse(example.body)["data"]
            not_in_process = data.select { |component| component["attributes"]["participatory_space_type"] != "Decidim::ParticipatoryProcess" && component["attributes"]["participatory_space_id"] != participatory_process.id.to_s }
            expect(not_in_process).to be_empty
          end
        end

        context "with per_page=2, list max two organizations" do
          let(:page) { 1 }
          let(:per_page) { 2 }

          before do
            manifests = Decidim.participatory_space_registry.manifests.map(&:name)
            10.times.each do
              create(:component, participatory_space: assembly, manifest_name: manifests.sample, published_at: Time.zone.now)
            end
          end

          run_test!(example_name: :paginated) do |example|
            json_response = JSON.parse(example.body)
            expect(json_response["data"].size).to eq(per_page)
          end
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with invalid locales[] fields" do
          let(:"locales[]") { ["invalid_locale"] }

          run_test! do |example|
            message = JSON.parse(example.body)["detail"]
            expect(message).to start_with("Not allowed locales:")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"
        before do
          controller = Decidim::Api::RestFull::Public::ComponentsController.new
          allow(controller).to receive(:index).and_raise(StandardError)
          allow(Decidim::Api::RestFull::Public::ComponentsController)
            .to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"
        run_test!(example_name: :server_error)
      end
    end
  end
end