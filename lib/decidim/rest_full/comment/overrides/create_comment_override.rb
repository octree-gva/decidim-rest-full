# frozen_string_literal: true

# Core +CreateComment+ assumes +ContentProcessor.parse+ always returns metadata (see +create_comment+).
# In some environments metadata can be nil; guard to avoid +nil[:user]+.
module Decidim
  module RestFull
    module Comment
      module CreateCommentMetadataGuard
        def create_comment
          parsed = Decidim::ContentProcessor.parse(form.body, current_organization: form.current_organization)
          meta = (parsed.metadata || {}).with_indifferent_access

          params = {
            author: current_user,
            commentable: form.commentable,
            root_commentable: root_commentable(form.commentable),
            body: { I18n.locale => parsed.rewrite },
            alignment: form.alignment,
            decidim_user_group_id: form.user_group_id,
            participatory_space: form.current_component.try(:participatory_space)
          }

          @comment = Decidim.traceability.create!(
            Decidim::Comments::Comment,
            current_user,
            params,
            visibility: "public-only"
          )

          mentioned_users = meta[:user]&.users || []
          mentioned_groups = meta[:user_group]&.groups || []
          Decidim::Comments::CommentCreation.publish(@comment, meta.to_h)
          send_notifications(mentioned_users, mentioned_groups)
        end
      end
    end
  end
end

unless Decidim::Comments::CreateComment.ancestors.include?(Decidim::RestFull::Comment::CreateCommentMetadataGuard)
  Decidim::Comments::CreateComment.prepend(Decidim::RestFull::Comment::CreateCommentMetadataGuard)
end
