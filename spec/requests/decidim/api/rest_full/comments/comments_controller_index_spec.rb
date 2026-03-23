# frozen_string_literal: true

require "swagger_helper"
require "decidim/proposals/test/factories"
require "decidim/comments/test/factories"
require "decidim/assemblies/test/factories"

RSpec.describe Decidim::Api::RestFull::Comment::CommentsController do
  path "/comments" do
    get "Comments" do
      tags "Comments"
      produces "application/json"
      operationId "comments"
      description "List comments for the current organization, scoped to spaces visible to the token actor. Supports Ransack filters (e.g. decidim_component_id_eq, decidim_author_id_eq with decidim_author_type_eq)."

      it_behaves_like "localized params"
      it_behaves_like "paginated params"
      it_behaves_like "resource params"
      it_behaves_like "ordered params", columns: %w(created_at updated_at rand)

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Comment::CommentsController,
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
        let(:space_manifest) { "participatory_processes" }
        let(:space_id) { participatory_process.id }
        let(:component_id) { proposal_component.id }

        response "200", "Comment list" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:comment_index_response)

          run_test!(example_name: :ok_default) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data.map { |d| d["id"] }).to include(comment.id.to_s)
          end

          context "when filtering by component id" do
            let(:"filter[decidim_component_id_eq]") { proposal_component.id }

            run_test!(example_name: :filter_by_component) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.map { |d| d["id"] }).to eq([comment.id.to_s])
            end
          end

          context "when filtering by author" do
            let(:"filter[decidim_author_id_eq]") { comment.decidim_author_id }
            let(:"filter[decidim_author_type_eq]") { comment.decidim_author_type }

            run_test!(example_name: :filter_by_author) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.map { |d| d["id"] }).to eq([comment.id.to_s])
            end
          end

          context "when another organization has comments" do
            let!(:other_org) { create(:organization, host: "other-comments.example.org") }
            let!(:other_process) { create(:participatory_process, :with_steps, organization: other_org) }
            let!(:other_component) { create(:proposal_component, participatory_space: other_process) }
            let!(:other_proposal) { create(:proposal, component: other_component) }
            let!(:other_comment) do
              create(
                :comment,
                commentable: other_proposal,
                root_commentable: other_proposal,
                participatory_space: other_proposal.participatory_space,
                author: create(:user, :confirmed, organization: other_org)
              )
            end

            run_test!(example_name: :org_scoped) do |example|
              data = JSON.parse(example.body)["data"]
              ids = data.map { |d| d["id"] }
              expect(ids).to include(comment.id.to_s)
              expect(ids).not_to include(other_comment.id.to_s)
            end
          end

          context "with transparent private assembly" do
            let!(:assembly) { create(:assembly, :private, :transparent, organization:) }
            let!(:asm_component) { create(:proposal_component, participatory_space: assembly) }
            let!(:asm_proposal) { create(:proposal, component: asm_component) }
            let!(:asm_comment) do
              create(
                :comment,
                commentable: asm_proposal,
                root_commentable: asm_proposal,
                participatory_space: assembly,
                author: create(:user, :confirmed, organization:)
              )
            end

            run_test!(example_name: :transparent_private_assembly_readable) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.map { |d| d["id"] }).to include(asm_comment.id.to_s)
            end
          end

          context "with private non-transparent assembly and non-member user" do
            let!(:assembly) { create(:assembly, :private, :opaque, organization:) }
            let!(:asm_component) { create(:proposal_component, participatory_space: assembly) }
            let!(:asm_proposal) { create(:proposal, component: asm_component) }
            let!(:hidden_comment) do
              create(
                :comment,
                commentable: asm_proposal,
                root_commentable: asm_proposal,
                participatory_space: assembly,
                author: create(:user, :confirmed, organization:)
              )
            end

            on_security(:impersonationFlow) do
              run_test!(example_name: :private_opaque_non_member_empty) do |example|
                data = JSON.parse(example.body)["data"]
                expect(data.map { |d| d["id"] }).not_to include(hidden_comment.id.to_s)
              end
            end
          end
        end
      end
    end
  end
end
