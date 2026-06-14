# frozen_string_literal: true

require "swagger_helper"

# Regression: chatbot "Read more" uses GET /blogs/:id with order=published_at&order_direction=desc and
# follows links.next. Two posts with the same published_at must not produce a non-deterministic LEAD/LAG
# chain (ResourcesController#order_string adds `id asc` as tie-break).
#
# Scenario: 3 posts — one on a newer day, two older posts sharing the exact same published_at.
# Sort DESC by published_at then id ASC among ties:
#   1st in chain = newest post (what users see first),
#   2nd in chain = tied post with lower id,
#   3rd in chain = tied post with higher id.
#
# Expectations:
#   - GET show for the newest → links.next.resource_id = 2nd post (lower id among tied pair),
#   - GET show for that 2nd post → links.next.resource_id = 3rd post,
#   - GET show for the 3rd → links.next is nil.

RSpec.describe Decidim::Api::RestFull::Blogs::BlogsController do
  path "/blogs/{id}" do
    get "Show a blog detail (pagination / same published_at)" do
      tags "Blogs"
      produces "application/json"
      security [{ credentialFlowBearer: ["blogs"] }, { resourceOwnerFlowBearer: ["blogs"] }]
      operationId "blog_show_pagination"
      description "Blog show links.next / links.prev when two posts share published_at (DESC + id tie-break)"
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
        let(:component_id) { pagination_component.id }
        let(:space_id) { participatory_process.id }
        let(:space_manifest) { "participatory_processes" }
        let(:"locales[]") { %w(en fr) }

        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:pagination_component) do
          create(:component, participatory_space: participatory_process, manifest_name: "blogs", published_at: Time.zone.now)
        end

        let(:shared_published_at) { 7.days.ago.change(usec: 0) }
        let!(:newest_post) do
          create(
            :post,
            component: pagination_component,
            published_at: 1.day.ago,
            author: create(:user, :confirmed, organization:)
          )
        end
        let!(:tied_post_lower_id) do
          create(
            :post,
            component: pagination_component,
            published_at: shared_published_at,
            author: create(:user, :confirmed, organization:)
          )
        end
        let!(:tied_post_higher_id) do
          create(
            :post,
            component: pagination_component,
            published_at: shared_published_at,
            author: create(:user, :confirmed, organization:)
          )
        end

        let(:second_in_desc_chain_id) { [tied_post_lower_id.id, tied_post_higher_id.id].min }
        let(:third_in_desc_chain_id) { [tied_post_lower_id.id, tied_post_higher_id.id].max }

        # Default path id for rswag shared examples (403 / 500); pagination examples override.
        let(:id) { newest_post.id }

        response "200", "Blog Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:blog_item_response)

          context "when three posts exist with two identical published_at and order is published_at DESC" do
            let(:order) { "published_at" }
            let(:order_direction) { "desc" }
            let(:"filter[state_not_eq]") { "rejected" }

            context "when the requested post is the newest (next is first tied row by id)" do
              let(:id) { newest_post.id }

              run_test! do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"].to_i).to eq(newest_post.id)
                expect(data["links"]["next"]["meta"]["resource_id"].to_i).to eq(second_in_desc_chain_id)
              end
            end

            context "when the requested post is second in the chain (next is third)" do
              let(:id) { second_in_desc_chain_id }

              run_test! do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"].to_i).to eq(second_in_desc_chain_id)
                expect(data["links"]["next"]["meta"]["resource_id"].to_i).to eq(third_in_desc_chain_id)
              end
            end

            context "when the requested post is third in the chain (no next)" do
              let(:id) { third_in_desc_chain_id }

              run_test! do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"].to_i).to eq(third_in_desc_chain_id)
                expect(data["links"]["next"]).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
