# frozen_string_literal: true

require "spec_helper"
require "decidim/proposals/test/factories"
require "decidim/comments/test/factories"

RSpec.describe Decidim::RestFull::Comment::CommentRansackers do
  before { described_class.register! }

  describe "decidim_component_id ransacker" do
    let(:proposal) { create(:proposal) }
    let!(:comment) do
      create(
        :comment,
        commentable: proposal,
        root_commentable: proposal,
        participatory_space: proposal.participatory_space
      )
    end

    it "filters comments by resolved component id" do
      q = Decidim::Comments::Comment.ransack(decidim_component_id_eq: proposal.decidim_component_id)
      expect(q.result).to include(comment)
    end

    context "with reply to comment" do
      let!(:reply) do
        create(
          :comment,
          commentable: comment,
          root_commentable: proposal,
          participatory_space: proposal.participatory_space
        )
      end

      it "resolves component from root for replies" do
        q = Decidim::Comments::Comment.ransack(decidim_component_id_eq: proposal.decidim_component_id)
        expect(q.result).to include(reply)
      end
    end
  end

  describe "CommentVote ransacker" do
    let(:proposal) { create(:proposal) }
    let!(:comment) do
      create(
        :comment,
        commentable: proposal,
        root_commentable: proposal,
        participatory_space: proposal.participatory_space
      )
    end
    let!(:vote) { create(:comment_vote, comment:, author: create(:user, organization: proposal.organization)) }

    it "filters votes by resolved component id" do
      q = Decidim::Comments::CommentVote.ransack(decidim_component_id_eq: proposal.decidim_component_id)
      expect(q.result).to include(vote)
    end
  end
end
