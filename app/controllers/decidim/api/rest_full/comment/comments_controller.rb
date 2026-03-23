# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Comment
        class CommentsController < ResourcesController
          before_action { doorkeeper_authorize! :comments }
          before_action :reject_client_credentials_mutations!, only: [:create, :update, :destroy, :hide]

          def index
            ability.authorize! :read, ::Decidim::Comments::Comment
            query = collection.ransack(params[:filter])
            results = query.result
            render json: ::Decidim::Api::RestFull::Comment::CommentSerializer.new(
              paginate(ordered(results)),
              params: serializer_params
            ).serializable_hash
          end

          def show
            ability.authorize! :read, ::Decidim::Comments::Comment
            comment = find_visible_comment!
            render json: ::Decidim::Api::RestFull::Comment::CommentSerializer.new(
              comment,
              params: serializer_params
            ).serializable_hash
          end

          def create
            require_user!(act_as)
            ability.authorize! :create, ::Decidim::Comments::Comment
            commentable = resolve_commentable!
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Not allowed to comment" unless comment_allowed?(:create, commentable:)

            form = build_comment_form(commentable)
            Decidim::Comments::CreateComment.call(form) do
              on(:ok) do |comment|
                return render json: ::Decidim::Api::RestFull::Comment::CommentSerializer.new(
                  comment,
                  params: serializer_params
                ).serializable_hash, status: :created
              end
              on(:invalid) do
                raise Decidim::RestFull::Core::ApiException::BadRequest, form.errors.full_messages.join(", ")
              end
            end
          end

          def update
            require_user!(act_as)
            ability.authorize! :update, ::Decidim::Comments::Comment
            comment = find_visible_comment!
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Not allowed" unless comment_allowed?(:update, commentable: comment.root_commentable, comment:)

            form = Decidim::Comments::CommentForm.from_params(
              update_comment_params.merge(commentable: comment.commentable)
            ).with_context(
              current_user: act_as,
              current_organization:,
              current_component: current_component_for(comment.commentable)
            )

            Decidim::Comments::UpdateComment.call(comment, form) do
              on(:ok) do
                comment.reload
                return render json: ::Decidim::Api::RestFull::Comment::CommentSerializer.new(
                  comment,
                  params: serializer_params
                ).serializable_hash
              end
              on(:invalid) do
                raise Decidim::RestFull::Core::ApiException::BadRequest, form.errors.full_messages.join(", ")
              end
            end
          end

          def destroy
            require_user!(act_as)
            ability.authorize! :destroy, ::Decidim::Comments::Comment
            comment = find_visible_comment!
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Not allowed" unless comment_allowed?(:destroy, commentable: comment.root_commentable, comment:)

            Decidim::Comments::DeleteComment.call(comment, act_as) do
              on(:ok) { return head :no_content }
              on(:invalid) { raise Decidim::RestFull::Core::ApiException::Forbidden, "Cannot delete comment" }
            end
          end

          def hide
            require_user!(act_as)
            ability.authorize! :moderate, ::Decidim::Comments::Comment
            comment = find_visible_comment!
            Decidim::ModerationTools.new(comment, act_as).hide!
            comment.reload
            render json: ::Decidim::Api::RestFull::Comment::CommentSerializer.new(
              comment,
              params: serializer_params
            ).serializable_hash
          end

          private

          def reject_client_credentials_mutations!
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Resource owner required" if service_token?
          end

          def collection
            Decidim::RestFull::Comment::CommentVisibility.visible_comments(self)
          end

          def find_visible_comment!
            comment = collection.find_by(id: params.require(:id))
            raise Decidim::RestFull::Core::ApiException::NotFound, "Comment not found" unless comment

            comment
          end

          def serializer_params
            {
              only: [],
              locales: available_locales,
              host: current_organization.host,
              act_as:
            }
          end

          def order_columns
            %w(created_at updated_at rand)
          end

          def default_order_column
            "created_at"
          end

          def resolve_commentable!
            type = create_comment_params[:decidim_commentable_type].to_s
            id = create_comment_params[:decidim_commentable_id]
            klass = type.safe_constantize
            raise Decidim::RestFull::Core::ApiException::BadRequest, "Unknown commentable type" unless klass

            record = klass.find_by(id:)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Commentable not found" unless record
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Invalid organization" unless commentable_in_organization?(record)

            record
          end

          def commentable_in_organization?(record)
            if record.respond_to?(:organization)
              record.organization == current_organization
            elsif record.respond_to?(:participatory_space)
              record.participatory_space&.organization == current_organization
            else
              true
            end
          end

          def build_comment_form(commentable)
            Decidim::Comments::CommentForm.from_params(
              create_comment_params.merge(commentable:)
            ).with_context(
              current_user: act_as,
              current_organization:,
              current_component: current_component_for(commentable)
            )
          end

          def current_component_for(commentable)
            return commentable.component if commentable.respond_to?(:component)
            return nil unless commentable.respond_to?(:participatory_space)

            space = commentable.participatory_space
            return space if space.is_a?(Decidim::Initiative)

            nil
          end

          def create_comment_params
            raw = params.require(:comment).permit(:decidim_commentable_type, :decidim_commentable_id, :alignment, body: {})
            raw.merge(body: comment_body_string_from(raw[:body]))
          end

          def update_comment_params
            raw = params.require(:comment).permit(body: {})
            raw.merge(body: comment_body_string_from(raw[:body]))
          end

          # +CommentForm+ expects a single string; API accepts a locale hash like proposals.
          def comment_body_string_from(body)
            return body.to_s if body.is_a?(String)

            h = if body.respond_to?(:to_unsafe_h)
                  body.to_unsafe_h.stringify_keys
                elsif body.is_a?(Hash)
                  body.stringify_keys
                else
                  {}
                end
            loc = current_locale.to_s
            (h[loc].presence || h.values.compact.first).to_s
          end

          def comment_allowed?(action, commentable:, comment: nil)
            user = act_as
            return false unless user

            permission_action = Decidim::PermissionAction.new(scope: :public, action:, subject: :comment)
            Decidim::Comments::Permissions.new(
              user,
              permission_action,
              {
                current_organization:,
                current_component: current_component_for(commentable),
                commentable:,
                comment:
              }.compact
            ).permissions.allowed?
          end

          def model_class
            Decidim::Comments::Comment
          end

          def component_manifest
            "comments"
          end
        end
      end
    end
  end
end
