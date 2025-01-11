# frozen_string_literal: true

require "swagger_helper"
RSpec.describe "Decidim::Api::RestFull::Blog::BlogsController", type: :request do
  path "/public/{space_manifest}/{space_id}/{component_id}/blogs" do
    get "Show a blog detail" do
      tags "Blogs"
      produces "application/json"
      security [{ credentialFlowBearer: ["blogs"] }, { resourceOwnerFlowBearer: ["blogs"] }]
      operationId "blogs"
      description "Get blog post list"

      parameter name: "locales[]", in: :query, style: :form, explode: true, schema: Api::Definitions::LOCALES_PARAM, required: false
      parameter name: "space_manifest", in: :path, schema: { type: :string, enum: Decidim.participatory_space_registry.manifests.map(&:name), description: "Space type" }
      parameter name: "space_id", in: :path, schema: { type: :integer, description: "Space Id" }
      parameter name: "component_id", in: :path, schema: { type: :integer, description: "Component Id" }
      parameter name: :page, in: :query, type: :integer, description: "Page number for pagination", required: false
      parameter name: :per_page, in: :query, type: :integer, description: "Number of items per page", required: false

      let!(:organization) { create(:organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
      let!(:blog_post) { create(:post, component: component, published_at: Time.zone.now - 2.days.ago, author: create(:user, :confirmed, organization: organization)) }
      let!(:blog_posts) { create_list(:post, 3, component: component, published_at: Time.zone.now - 1.day.ago, author: create(:user, :confirmed, organization: organization)) }
      let(:"locales[]") { %w(en fr) }

      let!(:api_client) do
        api_client = create(:api_client, scopes: ["blogs"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "blogs.read")
        ]
        api_client.save!
        api_client.reload
      end

      let(:user) { create(:user, locale: "fr", organization: organization) }

      # Routing
      let!(:impersonate_token) do
        create(:oauth_access_token, scopes: ["blogs"], resource_owner_id: user.id, application: api_client)
      end
      let(:Authorization) { "Bearer #{impersonate_token.token}" }
      let(:space_manifest) { "participatory_processes" }
      let(:space_id) { participatory_process.id }
      let(:component_id) { component.id }
      let(:post_id) { blog_post.id }

      before do
        host! organization.host
      end

      response "200", "Blogs Found" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/blogs_response"

        context "when is ordered" do
          let!(:posts) do
            [
              create(:post, component: component, author: create(:user, :confirmed, organization: organization)),
              create(:post, component: component, author: create(:user, :confirmed, organization: organization)),
              create(:post, component: component, author: create(:user, :confirmed, organization: organization))
            ].each_with_index do |post, index|
              post.published_at = (index + 1).minutes.ago
              post.save!
              post
            end
          end
          let!(:impersonate_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }

          let!(:post_id) { Decidim::Blogs::Post.where(component: component).order(published_at: :asc).first.id }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            posts = Decidim::Blogs::Post.where(component: component).order(published_at: :asc).ids
            expect(data.first["id"]).to eq(posts.first.to_s)
            expect(data.last["id"]).to eq(posts.last.to_s)
          end
        end

        context "when list own drafts" do
          let!(:draft_post) do
            post = create(:post, component: component, published_at: nil, decidim_author_id: user.id)
            post.published_at = 1.year.from_now
            post.save!
            post
          end

          let(:post_id) { draft_post.id }

          run_test!(example_name: :ok_drafts) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.find { |d| d["meta"]["published"] == false }["id"]).to eq(draft_post.id.to_s)
          end
        end

        
          context "with per_page=2, list max two blog posts" do
            let(:page) { 1 }
            let(:per_page) { 2 }
            let!(:impersonate_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }
            let!(:proposals) do
              [
                create(:post, component: component, author: create(:user, :confirmed, organization: organization)),
                create(:post, component: component, author: create(:user, :confirmed, organization: organization)),
                create(:post, component: component, author: create(:user, :confirmed, organization: organization))
              ].each_with_index do |post, index|
                post.published_at = (index + 1).minutes.ago
                post.save!
                post
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
            error_description = JSON.parse(example.body)["error_description"]
            expect(error_description).to start_with("Not allowed locales:")
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => "#/components/schemas/api_error"

        context "with no blogs scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no blogs.read permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["blogs"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response.status).to eq(403)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "500", "Internal Server Error" do
        consumes "application/json"
        produces "application/json"

        before do
          controller = Decidim::Api::RestFull::Blog::BlogsController.new
          allow(controller).to receive(:index).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Blog::BlogsController).to receive(:new).and_return(controller)
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
