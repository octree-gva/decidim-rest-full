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
      it_behaves_like "localized params"
      it_behaves_like "resource params"
      it_behaves_like "ordered params"
      parameter name: "id", in: :path, schema: { type: :integer, description: "Blog Post Id" }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Blogs::BlogsController,
        action: :show,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["blogs"],
        permissions: ["blogs.read"]
      ) do
        let(:id) { blog_post.id }
        let(:component_id) { component.id }
        let(:space_id) { participatory_process.id }
        let(:space_manifest) { "participatory_processes" }

        let(:"locales[]") { %w(en fr) }
        let!(:blog_post) { create(:post, component: component, published_at: Time.zone.now - 2.days.ago, author: create(:user, :confirmed, organization: organization)) }
        let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
        let!(:participatory_process) { create(:participatory_process, organization: organization) }

        response "200", "Blog Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:blog_item_response)

          context "when blog post is alone" do
            run_test! do |example|
              data = JSON.parse(example.body)["data"]
              expect(data["id"].to_i).to eq(blog_post.id.to_i)
              expect(data["links"]["next"]).to be_nil
              expect(data["links"]["prev"]).to be_nil
            end
          end

          context "when ordering by published_at DESC" do
            context "when selecting the last published blog, next is the 2nd last published blog, prev is nil" do
              let(:order) { "published_at" }
              let(:order_direction) { "desc" }
              let(:last_blog_component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
              let!(:first_blog) { create(:post, component: last_blog_component, published_at: 1.day.ago) }
              let!(:second_blog) { create(:post, component: last_blog_component, published_at: 2.days.ago) }
              let!(:third_blog) { create(:post, component: last_blog_component, published_at: 3.days.ago) }
              let(:"filter[state_not_eq]") { "rejected" }
              let(:component_id) { last_blog_component.id }
              let(:id) { first_blog.id }

              run_test! do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"].to_i).to eq(id.to_i)
                expect(data["meta"]["published"]).to be_truthy
                expect(data["links"]["next"]).to be_present
                expect(data["links"]["next"]["meta"]["resource_id"].to_i).to eq(second_blog.id.to_i)
                expect(data["links"]["prev"]).to be_nil
              end
            end

            context "when selecting the first published blog, prev is the second published blog, next is nil" do
              let(:order) { "published_at" }
              let(:order_direction) { "desc" }
              let(:last_blog_component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
              let!(:first_blog) { create(:post, component: last_blog_component, published_at: 1.day.ago) }
              let!(:second_blog) { create(:post, component: last_blog_component, published_at: 2.days.ago) }
              let!(:third_blog) { create(:post, component: last_blog_component, published_at: 3.days.ago) }
              let(:component_id) { last_blog_component.id }
              let(:id) { third_blog.id }

              run_test! do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"].to_i).to eq(id.to_i)
                expect(data["meta"]["published"]).to be_truthy
                expect(data["links"]["next"]).to be_nil
                expect(data["links"]["prev"]).to be_present
                expect(data["links"]["prev"]["meta"]["resource_id"].to_i).to eq(second_blog.id.to_i)
              end
            end
          end

          context "when blog post is the last one (published_at ASC)" do
            let(:order) { "published_at" }
            let(:order_direction) { "asc" }

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
              expect(data["id"].to_i).to eq(posts.last.to_i)
              expect(data["links"]["next"]).to be_nil
              expect(data["links"]["prev"]).to be_present
              expect(data["links"]["prev"]["meta"]["resource_id"].to_i).to eq(posts.last(2).first.to_i)
            end
          end

          context "when blog post is first one (published_at ASC)" do
            let(:order) { "published_at" }
            let(:order_direction) { "asc" }
            let!(:posts) do
              Array.new(3) { create(:post, component: component, author: create(:user, :confirmed, organization: organization)) }.each_with_index do |post, index|
                post.published_at = (index + 1).minutes.ago
                post.save!
                post
              end
            end
            let!(:impersonate_token) { create(:oauth_access_token, scopes: "blogs", resource_owner_id: nil, application: api_client) }
            let(:component_id) { component.id }
            let!(:id) { Decidim::Blogs::Post.where(component: component).order(published_at: :asc).first.id }

            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              posts = Decidim::Blogs::Post.where(component: component).order(published_at: :asc).ids
              expect(data["id"].to_i).to eq(posts.first.to_i)
              expect(data["links"]["prev"]).to be_nil
              expect(data["links"]["next"]).to be_present
              expect(data["links"]["next"]["meta"]["resource_id"].to_i).to eq(posts.second.to_i)
            end
          end

          context "when second blog post in a collectin of 3" do
            let(:order) { "published_at" }
            let(:order_direction) { "asc" }
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
              expect(data["id"].to_i).to eq(posts.second.to_i)
              expect(data["links"]).to be_present
              expect(data["links"]["next"]).to be_present
              expect(data["links"]["next"]["meta"]["resource_id"].to_i).to eq(posts.third.to_i)
              expect(data["links"]["prev"]).to be_present
              expect(data["links"]["prev"]["meta"]["resource_id"]).to eq(posts.first.to_s)
            end
          end

          on_security(:impersonationFlow) do
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
                expect(data["id"].to_i).to eq(draft_post.id.to_i)
                expect(data["meta"]["published"]).to be(false)
              end
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

        it_behaves_like "localized endpoint"
      end
    end
  end
end
