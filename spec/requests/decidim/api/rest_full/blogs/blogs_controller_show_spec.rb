# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Blogs::BlogsController do
  path "/blogs/{id}" do
    get "Show a blog detail" do
      tags "Blogs"
      produces "application/json"
      security [{ credentialFlowBearer: ["blogs"] }, { resourceOwnerFlowBearer: ["blogs"] }]
      operationId "blog"
      description "Get blog post details"

      let(:id) { blog_post.id }
      let(:component_id) { component.id }
      let(:space_id) { participatory_process.id }
      let(:space_manifest) { "participatory_processes" }
      let(:Authorization) { "Bearer #{impersonate_token.token}" }
      # Routing
      let!(:impersonate_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: user.id, application: api_client) }
      let(:user) { create(:user, locale: "fr", organization: organization) }
      let!(:api_client) do
        api_client = create(:api_client, scopes: ["blogs"], organization: organization)
        api_client.permissions = [
          api_client.permissions.build(permission: "blogs.read")
        ]
        api_client.save!
        api_client.reload
      end
      let(:"locales[]") { %w(en fr) }
      let!(:blog_post) { create(:post, component: component, published_at: Time.zone.now - 2.days.ago, author: create(:user, :confirmed, organization: organization)) }
      let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:organization) { create(:organization) }

      before do
        host! organization.host
      end

      it_behaves_like "localized endpoint"
      parameter name: "id", in: :path, schema: { type: :integer, description: "Blog Post Id" }
      parameter name: "component_id", in: :query, schema: { type: :integer, description: "Component Id" }, required: false

      response "200", "Blog Found" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:blog_item_response)

        context "when blog post is alone" do
          run_test! do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(blog_post.id.to_s)
            expect(data["links"]["next"]).to be_nil
            expect(data["links"]["prev"]).to be_nil
          end
        end

        context "when blog post is the last one" do
          let!(:post_list) do
            Array.new(3) { create(:post, component: component, author: create(:user, :confirmed, organization: organization)) }.each_with_index do |post, index|
              post.published_at = (index + 1).minutes.ago
              post.save!
              post
            end.reverse
          end
          let(:id) { blog_post.id }

          run_test!(example_name: :ok_no_more) do |example|
            data = JSON.parse(example.body)["data"]
            posts = Decidim::Blogs::Post.where(component: component).order(published_at: :asc).ids
            expect(data["id"]).to eq(posts.last.to_s)
            expect(data["links"]["next"]).to be_nil
            expect(data["links"]["prev"]).to be_present
            expect(data["links"]["prev"]["meta"]["resource_id"]).to eq(posts.last(2).first.to_s)
          end
        end

        context "when blog post is first one" do
          let!(:posts) do
            Array.new(3) { create(:post, component: component, author: create(:user, :confirmed, organization: organization)) }.each_with_index do |post, index|
              post.published_at = (index + 1).minutes.ago
              post.save!
              post
            end
          end
          let!(:impersonate_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }

          let!(:id) { Decidim::Blogs::Post.where(component: component).order(published_at: :asc).first.id }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            posts = Decidim::Blogs::Post.where(component: component).order(published_at: :asc).ids
            expect(data["id"]).to eq(posts.first.to_s)
            expect(data["links"]["prev"]).to be_nil
            expect(data["links"]["next"]).to be_present
            expect(data["links"]["next"]["meta"]["resource_id"]).to eq(posts.second.to_s)
          end
        end

        context "when second blog post in a collectin of 3" do
          let!(:posts) do
            Array.new(3) { create(:post, component: component, author: create(:user, :confirmed, organization: organization)) }.each_with_index do |post, index|
              post.published_at = (index + 1).minutes.ago
              post.save!
              post
            end
          end
          let!(:impersonate_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }

          let!(:id) { Decidim::Blogs::Post.where(component: component).order(published_at: :asc).second.id }

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            posts = Decidim::Blogs::Post.where(component: component).order(published_at: :asc).ids
            expect(data["id"]).to eq(posts.second.to_s)
            expect(data["links"]["next"]).to be_present
            expect(data["links"]["next"]["meta"]["resource_id"]).to eq(posts.third.to_s)
            expect(data["links"]["prev"]).to be_present
            expect(data["links"]["prev"]["meta"]["resource_id"]).to eq(posts.first.to_s)
          end
        end

        context "with draft" do
          let!(:draft_post) do
            post = create(:post, component: component, published_at: nil, decidim_author_id: user.id)
            post.published_at = 1.year.from_now
            post.save!
            post
          end

          let(:id) { draft_post.id }

          run_test!(example_name: :ok_draft) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(draft_post.id.to_s)
            expect(data["meta"]["published"]).to be(false)
          end
        end
      end

      response "403", "Forbidden" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "with no blogs scope" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["system"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "system", resource_owner_id: nil, application: api_client) }

          run_test!(example_name: :forbidden) do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end

        context "with no blogs.read permission" do
          let!(:api_client) { create(:api_client, organization: organization, scopes: ["blogs"]) }
          let!(:impersonation_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }

          run_test! do |_example|
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("Forbidden")
          end
        end
      end

      response "404", "Blog Not Found" do
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        context "when id=bad_string" do
          let(:id) { "bad_string" }

          run_test!
        end

        context "when id=not_found" do
          let(:id) { Decidim::Blogs::Post.last.id + 10 }

          run_test!(example_name: :not_found)
        end
      end

      response "400", "Bad Request" do
        consumes "application/json"
        produces "application/json"
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

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
        schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

        before do
          controller = Decidim::Api::RestFull::Blogs::BlogsController.new
          allow(controller).to receive(:show).and_raise(StandardError.new("Intentional error for testing"))
          allow(Decidim::Api::RestFull::Blogs::BlogsController).to receive(:new).and_return(controller)
        end

        run_test! do |response|
          expect(response.status).to eq(500)
          expect(response.body).to include("Internal Server Error")
        end
      end
    end
  end
end
