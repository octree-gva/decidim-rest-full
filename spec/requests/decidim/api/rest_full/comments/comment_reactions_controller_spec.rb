# frozen_string_literal: true

require "swagger_helper"
require "decidim/proposals/test/factories"
require "decidim/comments/test/factories"

RSpec.describe Decidim::Api::RestFull::Comment::CommentReactionsController do
  path "/comment_reactions" do
    get "Comment reactions" do
      tags "Comments"
      produces "application/json"
      operationId "commentReactions"
      description "List comment votes (reactions). Joins comments; supports filters such as weight_eq, decidim_comment_id_eq, decidim_component_id_eq, comment_decidim_participatory_space_id_eq (+ type)."

      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "resource params"
      it_behaves_like "ordered params", columns: %w(created_at)

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentReactionsController,
        action: :index,
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
        let!(:vote_author) { create(:user, :confirmed, organization:) }
        let!(:vote) { create(:comment_vote, :up_vote, comment:, author: vote_author) }

        response "200", "Reactions list" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:comment_reaction_index_response)

          run_test!(example_name: :ok_default) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.map { |d| d["id"] }).to include(vote.id.to_s)
          end

          context "when filtering by weight" do
            let(:"filter[weight_eq]") { 1 }

            run_test!(example_name: :filter_weight) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.all? { |d| d["attributes"]["weight"] == 1 }).to be true
            end
          end

          context "when filtering by comment id" do
            let(:"filter[decidim_comment_id_eq]") { comment.id }

            run_test!(example_name: :filter_comment_id) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.map { |d| d["id"] }).to eq([vote.id.to_s])
            end
          end

          context "when filtering by component id" do
            let(:"filter[decidim_component_id_eq]") { proposal_component.id }

            run_test!(example_name: :filter_component) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.map { |d| d["id"] }).to include(vote.id.to_s)
            end
          end

          context "when filtering by participatory space on joined comment" do
            let(:"filter[comment_decidim_participatory_space_id_eq]") { participatory_process.id }
            let(:"filter[comment_decidim_participatory_space_type_eq]") { "Decidim::ParticipatoryProcess" }

            run_test!(example_name: :filter_space_via_comment) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.map { |d| d["id"] }).to include(vote.id.to_s)
            end
          end
        end
      end
    end

    post "Create or toggle reaction" do
      tags "Comments"
      consumes "application/json"
      produces "application/json"
      operationId "createCommentReaction"
      description "Vote on a comment (weight 1 or -1). Repeating the same vote toggles it off. Requires impersonation."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:comment_reaction],
        properties: {
          comment_reaction: {
            type: :object,
            required: [:comment_id, :weight],
            properties: {
              comment_id: { type: :integer },
              weight: { type: :integer, enum: [-1, 1] }
            }
          }
        }
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentReactionsController,
        action: :create,
        security_types: [:impersonationFlow],
        scopes: ["comments"],
        permissions: %w(comments.read comments.vote)
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
            author: create(:user, :confirmed, organization:),
            body: { en: "root" }
          )
        end
        let(:body) { { comment_reaction: { comment_id: comment.id, weight: 1 } } }

        response "204", "Vote recorded or toggled off" do
          run_test!(example_name: :vote_ok) do
            expect(Decidim::Comments::CommentVote.exists?(decidim_comment_id: comment.id, decidim_author_id: user.id)).to be true
          end
        end
      end

      response "403", "Client credentials cannot vote" do
        consumes "application/json"
        produces "application/json"
        security [{ credentialFlowBearer: ["comments"] }]
        parameter name: :body, in: :body, required: true, schema: {
          type: :object,
          properties: {
            comment_reaction: {
              type: :object,
              properties: {
                comment_id: { type: :integer },
                weight: { type: :integer }
              }
            }
          }
        }
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let(:api_client) do
          c = create(:api_client, organization:, scopes: ["comments"])
          c.permissions = %w(comments.read comments.vote).map { |p| c.permissions.build(permission: p) }
          c.save!
          c
        end
        let!(:bearer_token) { create(:oauth_access_token, scopes: "comments", resource_owner_id: nil, application: api_client) }
        let(:Authorization) { "Bearer #{bearer_token.token}" }
        before { host! organization.host }

        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let!(:comment) do
          create(
            :comment,
            commentable: proposal,
            root_commentable: proposal,
            participatory_space: proposal.participatory_space,
            author: create(:user, :confirmed, organization:),
            body: { en: "x" }
          )
        end
        let(:body) { { comment_reaction: { comment_id: comment.id, weight: 1 } } }

        run_test!(example_name: :client_credentials_vote_forbidden)
      end
    end
  end
end
