# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Public::ComponentsController", type: :request do
  path "/public/components/{id}" do
    get "Show a Component" do
      tags "Public"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "component"
      description "Get details of a component"

      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: "id", in: :path, schema: { type: :integer }

      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:assembly) { create(:assembly, organization: organization) }
      let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "meetings", published_at: Time.zone.now) }
      let(:id) { component.id }
      let(:"locales[]") { %w(en fr) }

      let!(:api_client) { create(:api_client, organization: organization) }
      let(:user) { create(:user, locale: "fr", organization: organization) }

      let!(:impersonate_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: user.id, application: api_client) }
      let(:Authorization) { "Bearer #{impersonate_token.token}" }

      before do
        host! organization.host
        3.times.each do
          create(:meeting, component: component, published_at: Time.zone.now)
        end
        create(:meeting, component: component, published_at: Time.zone.now, private_meeting: true)
      end

      response "200", "Component Found" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/component_response"

        context "with no params" do
          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["relationships"]["resources"]["data"].size).to eq(4)
          end
        end

        context "with blog" do
          let!(:blog_component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
          let!(:blogs) { create_list(:post, 10, component: blog_component, author: create(:user, :confirmed, organization: organization), published_at: Time.zone.now) }
          let(:id) { blog_component.id }

          run_test!(example_name: :ok_blog) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["relationships"]["resources"]["data"].size).to eq(10)
          end
        end

        context "with empty blog" do
          let!(:blog_component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
          let(:id) { blog_component.id }

          run_test! do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["relationships"]["resources"]["data"].size).to eq(0)
          end
        end

        context "with published proposals, and drafted ones" do
          let!(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
          let!(:proposals) { create_list(:proposal, 10, component: proposal_component, published_at: Time.zone.now) }
          let!(:draft_proposals) do
            proposal = create(:proposal, component: proposal_component, published_at: nil)
            proposal.coauthorships.create(decidim_author_id: user.id, decidim_author_type: "Decidim::UserBaseEntity")
            proposal.save!
            create(:proposal, component: proposal_component, published_at: nil)
          end
          let(:id) { proposal_component.id }

          run_test!(example_name: :ok_proposal) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["relationships"]["resources"]["data"].size).to eq(11)
          end
        end

        context "with empty proposal" do
          let!(:proposal_component) { create(:component, participatory_space: participatory_process, manifest_name: "proposals", published_at: Time.zone.now) }
          let(:id) { proposal_component.id }

          run_test! do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["relationships"]["resources"]["data"].size).to eq(0)
          end
        end

        context "with locales[]=fr" do
          let(:"locales[]") { %w(fr) }

          run_test!(example_name: :select_FR_locale) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["name"]).not_to have_key "en"
            expect(data["attributes"]["name"]).to have_key "fr"
          end
        end
      end

      response "404", "Component Not Found" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "when id=bad_string" do
          let(:id) { "bad_string" }

          run_test!
        end

        context "when id=not_found" do
          let(:id) { Decidim::Component.last.id + 1 }

          run_test!(example_name: :not_found)
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with invalid locales[] fields" do
          let(:"locales[]") { ["invalid_locale"] }

          run_test! do |example|
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to start_with("Not allowed locales:")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Public::ComponentsController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Public::ComponentsController).to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Intentional error for testing")
        end
      end
    end
  end
end
