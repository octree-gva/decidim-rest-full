# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Comment
        class CommentReactionSerializer < ::Decidim::Api::RestFull::Core::ApplicationSerializer
          set_type :comment_reaction

          attributes :weight

          attribute :created_at do |vote|
            vote.created_at.iso8601
          end

          has_one :author, serializer: Core::UserSerializer, &:author

          has_one :comment, serializer: CommentSerializer, &:comment

          link :self do |vote, params|
            {
              href: "https://#{params[:host]}/comment_reactions/#{vote.id}",
              title: "Comment reaction",
              rel: "resource",
              meta: { action_method: "GET" }
            }
          end
        end
      end
    end
  end
end
