# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Components::BlogComponentsController do
  path "/components/blog_components/{id}" do
    get "Blog Component Details" do
      tags "Components"
      produces "application/json"
      operationId "blog_component"
      description "Blog component details"
      it_behaves_like "localized params"

      parameter name: "id", in: :path, schema: { type: :integer }
      parameter name: "component_id", in: :query, schema: { type: :integer, description: "Component Id" }, required: false
      parameter name: "space_manifest", in: :query, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }, required: false
      parameter name: "space_id", in: :query, schema: { type: :integer, description: "Space Id" }, required: false

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Components::BlogComponentsController,
        action: :show,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["public"],
        permissions: ["public.component.read"]
      ) do
        let(:id) { component.id }

        let(:component) { create(:component, manifest_name: "blogs") }
        let!(:assembly) { create(:assembly, organization: organization) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }

        before do
          blog_component = create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now)
          create(:post, component: blog_component)
          create(:post, component: blog_component)
        end

        it_behaves_like "localized endpoint"

        response "200", "Blog Component" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:blog_component_item_response)

          context "with no filter params" do
            let(:"locales[]") { %w(en fr) }
            let(:page) { 1 }
            let(:per_page) { 10 }

            run_test!(example_name: :ok)
          end
        end
      end
    end
  end
end
