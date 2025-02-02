# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::BlogComponentsController, type: :request do
  path "/components/blog_components/{id}" do
    get "Blog Component Details" do
      tags "Components"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "blog_component"
      description "Blog component details"

      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: "id", in: :path, schema: { type: :integer }

      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
      let!(:assembly) { create(:assembly, organization: organization) }
      let(:component) { create(:component, manifest_name: "blogs") }

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["public"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "public.component.read")
        ]
        api_client.save!
        api_client.reload
      end
      let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }
      let(:Authorization) { "Bearer #{impersonation_token.token}" }
      let(:id) {component.id}

      before do
        host! organization.host

        blog_component = create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now)
        create(:post, component: blog_component)
        create(:post, component: blog_component)

      end

      response "200", "Blog Component" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/component_response"

        context "with no filter params" do
          let(:"locales[]") { %w(en fr) }
          let(:page) { 1 }
          let(:per_page) { 10 }

          run_test!(example_name: :ok)
        end

      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with no public scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no public.component.read permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["public"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "public", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
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
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to start_with("Not allowed locales:")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Components::BlogComponentsController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Components::BlogComponentsController).to receive(:new).and_return(controller)
        end

        schema "$ref" => "#/components/schemas/api_error"

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
