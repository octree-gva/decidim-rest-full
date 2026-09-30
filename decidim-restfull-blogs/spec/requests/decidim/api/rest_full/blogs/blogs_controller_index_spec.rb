# frozen_string_literal: true

require "swagger_helper"
RSpec.describe Decidim::Api::RestFull::Blogs::BlogsController do
  path "/blogs" do
    get "List posts" do
      tags "Blogs"
      produces "application/json"
      operationId "listBlogPosts"
      description "List posts (Decidim::Blogs::Post)"

      let(:post_id) { blog_post.id }
      let(:component_id) { component.id }
      let(:space_id) { participatory_process.id }
      let(:space_manifest) { "participatory_processes" }

      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "resource params"
      it_behaves_like "ordered params", columns: %w(rand published_at)

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Blogs::BlogsController,
        action: :index,
        security_types: [:impersonationFlow, :credentialFlow],
        scopes: ["blogs"],
        permissions: ["blogs.read"]
      ) do
        let(:"locales[]") { %w(en fr) }
        let!(:blog_posts) { create_list(:post, 3, component:, published_at: 1.day.ago, author: create(:user, :confirmed, organization:)) }
        let!(:blog_post) { create(:post, component:, published_at: 2.days.ago, author: create(:user, :confirmed, organization:)) }
        let!(:component) { create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now) }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        it_behaves_like "localized endpoint"

        response "200", "Blogs Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:blog_index_response)

          context "when no posts (empty list)" do
            before do
              Decidim::Blogs::Post.where(component:).destroy_all
            end

            run_test!(example_name: :ok_empty) do |example|
              body = JSON.parse(example.body)
              expect(body["data"]).to eq([])
              meta = body.fetch("meta")
              expect(meta["page"]).to eq(1)
              expect(meta["per_page"]).to eq(20)
              expect(meta["has_more"]).to be(false)
              expect(meta["next"]).to be_nil
              expect(meta["prev"]).to be_nil
            end
          end

          on_security(:impersonationFlow) do
            context "when list own drafts" do
              let!(:draft_post) do
                post = create(:post, component:, published_at: nil, decidim_author_id: user.id)
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

          context "when filtered by component_id" do
            let!(:other_component) do
              create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now)
            end
            let!(:other_post) do
              create(:post, component: other_component, published_at: 1.day.ago, author: create(:user, :confirmed, organization:))
            end
            let(:component_id) { other_component.id }

            run_test!(example_name: :filtered_by_component) do |example|
              ids = JSON.parse(example.body)["data"].map { |row| row["id"] }
              expect(ids).to eq([other_post.id.to_s])
            end
          end

          # Regression: published filter must apply before ordered(); otherwise drafts inflate
          # limit+1 and the last page keeps has_more=true (production: 2 published + drafts).
          context "when two published posts are sorted and paginated" do
            let(:order) { "published_at" }
            let(:order_direction) { "desc" }
            let(:per_page) { 1 }
            let(:author) { create(:user, :confirmed, organization:) }
            let!(:older_post) { create(:post, component:, author:, published_at: 2.days.ago) }
            let!(:newer_post) { create(:post, component:, author:, published_at: 1.day.ago) }

            before do
              Decidim::Blogs::Post.where(component:).where.not(id: [older_post.id, newer_post.id]).destroy_all
              create(
                :post,
                component:,
                author:,
                published_at: 1.year.from_now
              )
            end

            context "when page=1" do
              let(:page) { 1 }

              run_test!(example_name: :ok_sorted_and_paginated) do |example|
                body = JSON.parse(example.body)
                expect(body["data"].map { |row| row["id"] }).to eq([newer_post.id.to_s])
                meta = body.fetch("meta")
                expect(meta["page"]).to eq(1)
                expect(meta["per_page"]).to eq(1)
                expect(meta["has_more"]).to be(true)
                expect(meta["next"]).to be_present
                expect(meta["prev"]).to be_nil
              end
            end

            context "when page=2 (last page)" do
              let(:page) { 2 }

              run_test!(example_name: :ok_sorted_and_paginated_last) do |example|
                body = JSON.parse(example.body)
                expect(body["data"].map { |row| row["id"] }).to eq([older_post.id.to_s])
                meta = body.fetch("meta")
                expect(meta["page"]).to eq(2)
                expect(meta["per_page"]).to eq(1)
                expect(meta["has_more"]).to be(false)
                expect(meta["next"]).to be_nil
                expect(meta["prev"]).to be_present
              end
            end
          end

          it_behaves_like "ordered endpoint", columns: %w(rand published_at) do
            let(:create_resource) { -> { create(:post, component:, author: create(:user, :confirmed, organization:)) } }
            let(:each_resource) do
              lambda { |resource, index|
                resource.published_at = (index + 1).minutes.ago
                resource.save!
              }
            end

            let(:resources) { Decidim::Blogs::Post.all }
          end

          it_behaves_like "paginated endpoint" do
            let(:create_resource) { -> { create(:post, component:, author: create(:user, :confirmed, organization:)) } }
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
