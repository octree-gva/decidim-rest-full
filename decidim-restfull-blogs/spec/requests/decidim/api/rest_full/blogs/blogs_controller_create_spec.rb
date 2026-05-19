# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Blogs::BlogsController do
  path "/blogs" do
    post "Create blog post (async)" do
      tags "Blogs"
      consumes "application/json"
      produces "application/json"
      operationId "createBlogPostAsync"
      description <<~README
        Enqueue creation of a blog post. Poll `GET /jobs/:uuid`.

        Set `published_at` to control visibility (see **Blogs** tag). Requires `blogs.write` and impersonation.
      README
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:blog_post_create_payload) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Blogs::BlogsController,
        action: :create,
        security_types: [:impersonationFlow],
        scopes: ["blogs"],
        permissions: ["blogs.write"]
      ) do
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:blog_component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
        let(:body) do
          {
            data: {
              component_id: blog_component.id,
              attributes: {
                title: { en: "New post" },
                body: { en: "Content" },
                published_at: 1.day.ago.iso8601
              }
            }
          }
        end

        response "202", "Job accepted" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_accepted)
          run_test!(example_name: :accepted) do |response|
            expect(response).to have_http_status(:accepted)
            expect(JSON.parse(response.body)).to include("job_id")
          end
        end
      end
    end
  end

  path "/blogs/{id}" do
    delete "Delete blog post (async)" do
      tags "Blogs"
      operationId "deleteBlogPostAsync"
      description "Enqueue deletion of a blog post. Requires `blogs.destroy`."

      parameter name: :id, in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Blogs::BlogsController,
        action: :destroy,
        security_types: [:impersonationFlow],
        scopes: ["blogs"],
        permissions: ["blogs.destroy"]
      ) do
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:blog_component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
        let!(:post) { create(:post, component: blog_component, author: user, published_at: 1.day.ago) }
        let(:id) { post.id }

        response "202", "Job accepted" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_accepted)
          run_test!(example_name: :accepted) do |response|
            expect(response).to have_http_status(:accepted)
            expect(JSON.parse(response.body)).to include("job_id")
          end
        end
      end
    end
  end
end
