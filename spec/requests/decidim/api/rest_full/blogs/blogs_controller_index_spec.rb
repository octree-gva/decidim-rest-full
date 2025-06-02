# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Blogs::BlogsController do
  path "/blogs" do
    get "Blog Post Lists" do
      tags "Blogs"
      produces "application/json"
      operationId "blogs"
      description "Get blog post list"

      let(:post_id) { blog_post.id }
      let(:component_id) { component.id }
      let(:space_id) { participatory_process.id }
      let(:space_manifest) { "participatory_processes" }

      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "resource params"
      it_behaves_like "ordered params"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Blogs::BlogsController,
        action: :index,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["blogs"],
        permissions: ["blogs.read"]
      ) do
        let(:"locales[]") { %w(en fr) }
        let!(:blog_posts) { create_list(:post, 3, component: component, published_at: Time.zone.now - 1.day.ago, author: create(:user, :confirmed, organization: organization)) }
        let!(:blog_post) { create(:post, component: component, published_at: Time.zone.now - 2.days.ago, author: create(:user, :confirmed, organization: organization)) }
        let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
        let!(:participatory_process) { create(:participatory_process, organization: organization) }
        it_behaves_like "localized endpoint"

        response "200", "Blogs Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:blog_index_response)
          on_security(:impersonationFlow) do
            context "when list own drafts" do
              let!(:draft_post) do
                post = create(:post, component: component, published_at: nil, decidim_author_id: user.id)
                post.published_at = 1.year.from_now
                post.save!
                post
              end

              let(:post_id) { draft_post.id }

              run_test!(example_name: :impersonation_ok_draft) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data.find { |d| d["meta"]["published"] == false }["id"]).to eq(draft_post.id.to_s)
              end
            end
          end

          it_behaves_like "ordered endpoint", columns: [
            "published_at"
          ] do
            let(:create_resource) { -> { create(:post, component: component, author: create(:user, :confirmed, organization: organization)) } }
            let(:each_resource) do
              lambda { |resource, index|
                resource.published_at = (index + 1).minutes.ago
                resource.save!
              }
            end

            let(:resources) { Decidim::Blogs::Post.all }
          end

          it_behaves_like "paginated endpoint" do
            let(:create_resource) { -> { create(:post, component: component, author: create(:user, :confirmed, organization: organization)) } }
            let(:each_resource) do
              lambda { |resource, index|
                resource.published_at = (index + 1).minutes.ago
                resource.save!
              }
            end

            let(:resources) { Decidim::Blogs::Post.all }
          end
        end
      end
    end
  end
end
