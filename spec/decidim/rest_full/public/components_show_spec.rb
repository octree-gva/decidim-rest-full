# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Public::ComponentsController", type: :request do
  path "/api/rest_full/v#{Decidim::RestFull.major_minor_version}/public/components/{id}" do
    get "Show a Component" do
      tags "Public"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: "id", in: :path, schema: { type: :integer }

      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:assembly) { create(:assembly, organization: organization) }
      let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "meetings", published_at: Time.zone.now) }
      let(:id) { component.id }
      let(:"locales[]") { %w(en fr) }

      let!(:api_client) { create(:api_client, organization: organization) }
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
      let(:Authorization) { "Bearer #{impersonation_token.token}" }

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
          allow(controller).to receive(:show).and_raise(StandardError)
          allow(Decidim::Api::RestFull::Public::ComponentsController)
            .to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"
        run_test!(example_name: :server_error)
      end
    end
  end
end
