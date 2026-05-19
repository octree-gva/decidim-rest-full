# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposals
        class VoteProposalSerializer < Decidim::Api::RestFull::Core::ApplicationSerializer
          set_type :vote_proposals

          attributes :weight

          attribute :created_at do |vote|
            vote.created_at.iso8601
          end

          attribute :updated_at do |vote|
            vote.updated_at.iso8601
          end

          belongs_to :proposal, record_type: :proposals, &:proposal

          belongs_to :author, record_type: :users, &:author
        end
      end
    end
  end
end
