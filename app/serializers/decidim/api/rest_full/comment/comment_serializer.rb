# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Comment
        class CommentSerializer < ::Decidim::Api::RestFull::Core::ApplicationSerializer
          set_type :comment

          attributes :alignment, :depth

          attribute :body do |comment, params|
            Core::ApplicationSerializer.translated_field(comment.body, params[:locales])
          end

          attribute :replies_count, &:comments_count

          attribute :created_at do |comment|
            comment.created_at.iso8601
          end

          attribute :updated_at do |comment|
            comment.updated_at.iso8601
          end

          attribute :commentable_type do |comment|
            comment.commentable.class.name
          end

          attribute :commentable_id do |comment|
            comment.commentable.id.to_s
          end

          attribute :root_commentable_type do |comment|
            comment.root_commentable.class.name
          end

          attribute :root_commentable_id do |comment|
            comment.root_commentable.id.to_s
          end

          has_one :author, serializer: Core::UserSerializer, &:author

          has_one :participatory_space, serializer: Core::SpaceSerializer, if: (proc do |comment|
            comment.participatory_space.present?
          end), &:participatory_space

          has_one :component, if: (proc do |comment|
            comment.component.present?
          end), serializer: proc { |comp|
            Decidim::Api::RestFull::Core::SerializerLookup.component_serializer_class_for(comp.manifest_name)
          }, &:component

          meta do |comment, _params|
            {
              hidden: comment.hidden?,
              deleted: comment.deleted_at.present?,
              edited: comment.edited?,
              primary_locale: comment.body.keys.first&.to_s,
              up_votes_count: comment.up_votes_count,
              down_votes_count: comment.down_votes_count
            }
          end

          link :self do |comment, params|
            {
              href: "https://#{params[:host]}/comments/#{comment.id}",
              title: "Comment",
              rel: "resource",
              meta: { action_method: "GET" }
            }
          end
        end
      end
    end
  end
end
