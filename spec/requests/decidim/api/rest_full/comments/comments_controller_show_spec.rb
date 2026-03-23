# frozen_string_literal: true

require "swagger_helper"
require "decidim/proposals/test/factories"
require "decidim/comments/test/factories"

RSpec.describe Decidim::Api::RestFull::Comment::CommentsController do
  path "/comments/{id}" do
    get "Comment" do
      tags "Comments"
      produces "application/json"
      operationId "comment"
      description "Get a single comment by id (organization and visibility scoped)."

      it_behaves_like "localized params"
      it_behaves_like "resource params"
      parameter name: "id", in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentsController,
        action: :show,
        security_types: [:credentialFlow, :impersonationFlow],
        scopes: ["comments"],
        permissions: ["comments.read"]
      ) do
        let(:"locales[]") { %w(en fr) }
        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let!(:comment) do
          create(
            :comment,
            commentable: proposal,
            root_commentable: proposal,
            participatory_space: proposal.participatory_space,
            author: create(:user, :confirmed, organization:)
          )
        end
        let(:id) { comment.id }
        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }
        let(:component_id) { proposal_component.id }

        response "200", "Comment found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:comment_item_response)

          run_test!(example_name: :ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(comment.id.to_s)
            expect(data["type"]).to eq("comment")
          end
        end

        response "404", "Not found" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

          context "when id does not exist" do
            let(:id) { Decidim::Comments::Comment.maximum(:id).to_i + 1 }

            run_test!(example_name: :not_found)
          end

          context "when comment belongs to another organization" do
            let!(:other_org) { create(:organization, host: "other-show.example.org") }
            let!(:other_process) { create(:participatory_process, :with_steps, organization: other_org) }
            let!(:other_component) { create(:proposal_component, participatory_space: other_process) }
            let!(:other_proposal) { create(:proposal, component: other_component) }
            let!(:foreign_comment) do
              create(
                :comment,
                commentable: other_proposal,
                root_commentable: other_proposal,
                participatory_space: other_proposal.participatory_space,
                author: create(:user, :confirmed, organization: other_org)
              )
            end
            let(:id) { foreign_comment.id }

            run_test!(example_name: :wrong_org)
          end
        end
      end
    end
  end
end
