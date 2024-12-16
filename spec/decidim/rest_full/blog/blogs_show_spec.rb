# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Blog::BlogsController", type: :request do
  path "/public/{space_manifest}/{space_id}/{component_id}/blogs/{post_id}" do
    get "Show a blog detail" do
      tags "Public"
      produces "application/json"
      security [{ credentialFlowBearer: ["public"] }, { resourceOwnerFlowBearer: ["public"] }]
      operationId "component"
      description "Get blog post details"

      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: "space_manifest", in: :path, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }
      parameter name: "space_id", in: :path, schema: { type: :integer, description: "Space Id" }
      parameter name: "component_id", in: :path, schema: { type: :integer, description: "Component Id" }
      parameter name: "post_id", in: :path, schema: { type: :integer, description: "Blog Post Id" }

      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
      let!(:blog_post) { create(:post, component: component, published_at: Time.zone.now, author: create(:user, :confirmed, organization: organization)) }
      let(:"locales[]") { %w(en fr) }

      let!(:api_client) { create(:api_client, organization: organization) }
      let(:user) { create(:user, locale: "fr", organization: organization) }

      # Routing
      let!(:impersonate_token) { create(:oauth_access_token, scopes: "blog", resource_owner_id: user.id, application: api_client) }
      let(:Authorization) { "Bearer #{impersonate_token.token}" }
      let(:space_manifest) { "participatory_processes" }
      let(:space_id) { participatory_process.id }
      let(:component_id) { component.id }
      let(:post_id) { blog_post.id }

      before do
        host! organization.host
      end

      response "200", "Blog Found" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/blog_response"

        context "with no params" do
          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(blog_post.id.to_s)
          end
        end

        context "with draft" do
          let!(:draft_post) do
            post = create(:post, component: component, published_at: nil, decidim_author_id: user.id)
            post.published_at = 1.year.from_now
            post.save!
            post
          end

          let(:post_id) { draft_post.id }

          run_test!(example_name: :ok_draft) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(draft_post.id.to_s)
            expect(data["meta"]["published"]).to be(false)
          end
        end
      end

      response "404", "Blog Not Found" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "when post_id=bad_string" do
          let(:post_id) { "bad_string" }

          run_test!
        end

        context "when id=not_found" do
          let(:post_id) { Decidim::Blogs::Post.last.id + 10 }

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
          controller = Decidim::Api::RestFull::Blog::BlogsController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Blog::BlogsController).to receive(:new).and_return(controller)
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
