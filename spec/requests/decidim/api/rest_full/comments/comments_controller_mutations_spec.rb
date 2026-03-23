# frozen_string_literal: true

require "swagger_helper"
require "decidim/proposals/test/factories"
require "decidim/comments/test/factories"

RSpec.describe Decidim::Api::RestFull::Comment::CommentsController do
  path "/comments" do
    post "Create comment" do
      tags "Comments"
      consumes "application/json"
      produces "application/json"
      operationId "createComment"
      description "Create a comment on a commentable resource. Requires impersonation (resource owner token); client-credentials tokens are rejected."

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:comment],
        properties: {
          comment: {
            type: :object,
            required: [:decidim_commentable_type, :decidim_commentable_id, :body],
            properties: {
              decidim_commentable_type: { type: :string, example: "Decidim::Proposals::Proposal" },
              decidim_commentable_id: { type: :integer },
              alignment: { type: :integer, enum: [-1, 0, 1] },
              body: { type: :object, additionalProperties: { type: :string } }
            }
          }
        }
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentsController,
        action: :create,
        security_types: [:impersonationFlow],
        scopes: ["comments"],
        permissions: %w(comments.read comments.create)
      ) do
        let(:"locales[]") { %w(en fr) }
        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let(:body) do
          {
            comment: {
              decidim_commentable_type: "Decidim::Proposals::Proposal",
              decidim_commentable_id: proposal.id,
              alignment: 0,
              body: { en: "Hello from API" }
            }
          }
        end

        response "201", "Created" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:comment_item_response)

          run_test!(example_name: :created) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["body"]["en"]).to eq("Hello from API")
            expect(data["relationships"]["author"]["data"]["id"]).to eq(user.id.to_s)
          end
        end

        response "403", "Forbidden when comments disabled" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)
          let!(:proposal_component) { create(:proposal_component, :with_comments_disabled, participatory_space: participatory_process) }
          let!(:proposal) { create(:proposal, component: proposal_component) }

          run_test!(example_name: :comments_disabled)
        end

        # Unpublished space/component write policy (plan scenario 14) is stricter than core
        # +Decidim::Comments::Permissions+ alone; add explicit checks in the controller when product requires it.
      end

      response "403", "Client credentials cannot create" do
        consumes "application/json"
        produces "application/json"
        security [{ credentialFlowBearer: ["comments"] }]
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let(:api_client) do
          c = create(:api_client, organization:, scopes: ["comments"])
          c.permissions = %w(comments.read comments.create).map { |p| c.permissions.build(permission: p) }
          c.save!
          c
        end
        let!(:bearer_token) { create(:oauth_access_token, scopes: "comments", resource_owner_id: nil, application: api_client) }
        let(:Authorization) { "Bearer #{bearer_token.token}" }

        before { host! organization.host }

        let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
        let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:proposal) { create(:proposal, component: proposal_component) }
        let(:body) do
          {
            comment: {
              decidim_commentable_type: "Decidim::Proposals::Proposal",
              decidim_commentable_id: proposal.id,
              body: { en: "nope" }
            }
          }
        end

        run_test!(example_name: :client_credentials_create_forbidden)
      end
    end
  end

  path "/comments/{id}" do
    patch "Update comment" do
      tags "Comments"
      consumes "application/json"
      produces "application/json"
      operationId "updateComment"
      parameter name: "id", in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:comment],
        properties: {
          comment: {
            type: :object,
            required: [:body],
            properties: {
              body: { type: :object, additionalProperties: { type: :string } }
            }
          }
        }
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentsController,
        action: :update,
        security_types: [:impersonationFlow],
        scopes: ["comments"],
        permissions: %w(comments.read comments.update)
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
            author: user,
            body: { en: "Original" }
          )
        end
        let(:id) { comment.id }
        let(:body) { { comment: { body: { en: "Updated text" } } } }

        response "200", "Updated" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:comment_item_response)

          run_test!(example_name: :updated) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["attributes"]["body"]["en"]).to eq("Updated text")
          end
        end

        response "403", "Cannot update someone else's comment" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)
          let!(:comment) do
            create(
              :comment,
              commentable: proposal,
              root_commentable: proposal,
              participatory_space: proposal.participatory_space,
              author: create(:user, :confirmed, organization:),
              body: { en: "Not mine" }
            )
          end

          run_test!(example_name: :not_author)
        end
      end

      response "403", "Client credentials cannot update" do
        consumes "application/json"
        produces "application/json"
        security [{ credentialFlowBearer: ["comments"] }]
        parameter name: "id", in: :path, schema: { type: :integer }, required: true
        parameter name: :body, in: :body, required: true, schema: {
          type: :object,
          properties: {
            comment: {
              type: :object,
              properties: { body: { type: :object, additionalProperties: { type: :string } } }
            }
          }
        }
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let(:author) { create(:user, :confirmed, organization:) }
        let(:api_client) do
          c = create(:api_client, organization:, scopes: ["comments"])
          c.permissions = %w(comments.read comments.update).map { |p| c.permissions.build(permission: p) }
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
            author:,
            body: { en: "x" }
          )
        end
        let(:id) { comment.id }
        let(:body) { { comment: { body: { en: "hack" } } } }

        run_test!(example_name: :client_credentials_update_forbidden)
      end
    end

    delete "Delete comment" do
      tags "Comments"
      produces "application/json"
      operationId "deleteComment"
      parameter name: "id", in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentsController,
        action: :destroy,
        security_types: [:impersonationFlow],
        scopes: ["comments"],
        permissions: %w(comments.read comments.destroy)
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
            author: user,
            body: { en: "delete me" }
          )
        end
        let(:id) { comment.id }

        response "204", "Deleted" do
          run_test!(example_name: :deleted) do
            expect(comment.reload.deleted_at).to be_present
          end
        end
      end

      response "403", "Client credentials cannot delete" do
        consumes "application/json"
        produces "application/json"
        security [{ credentialFlowBearer: ["comments"] }]
        parameter name: "id", in: :path, schema: { type: :integer }, required: true
        schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:error_response)

        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let(:author) { create(:user, :confirmed, organization:) }
        let(:api_client) do
          c = create(:api_client, organization:, scopes: ["comments"])
          c.permissions = %w(comments.read comments.destroy).map { |p| c.permissions.build(permission: p) }
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
            author:,
            body: { en: "x" }
          )
        end
        let(:id) { comment.id }

        run_test!(example_name: :client_credentials_delete_forbidden)
      end
    end
  end

  path "/comments/{id}/hide" do
    post "Hide comment" do
      tags "Comments"
      produces "application/json"
      operationId "hideComment"
      description "Moderate/hide a comment (requires comments.moderate)."
      parameter name: "id", in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentsController,
        action: :hide,
        security_types: [:impersonationFlow],
        scopes: ["comments"],
        permissions: %w(comments.read comments.moderate)
      ) do
        let(:"locales[]") { %w(en fr) }
        let!(:organization) { create(:organization, available_locales: ["en"]) }
        let(:user) { create(:user, :admin, organization:) }
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
            body: { en: "spam" }
          )
        end
        let(:id) { comment.id }

        response "200", "Hidden" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:comment_item_response)

          run_test!(example_name: :hidden) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["meta"]["hidden"]).to be true
          end
        end
      end
    end
  end
end
