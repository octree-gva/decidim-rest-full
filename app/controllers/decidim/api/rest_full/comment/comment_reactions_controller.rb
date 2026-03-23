# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Comment
        class CommentReactionsController < ApplicationController
          before_action { doorkeeper_authorize! :comments }
          before_action :reject_client_credentials_mutations!, only: [:create]

          def index
            ability.authorize! :read, ::Decidim::Comments::Comment
            query = collection.ransack(params[:filter])
            results = query.result
            render json: ::Decidim::Api::RestFull::Comment::CommentReactionSerializer.new(
              paginate(ordered(results)),
              params: serializer_params
            ).serializable_hash
          end

          def create
            require_user!(act_as)
            ability.authorize! :vote, ::Decidim::Comments::CommentVote
            comment = find_comment_for_vote!
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Not allowed to vote" unless vote_allowed?(comment)

            weight = vote_weight_param
            Decidim::Comments::VoteComment.call(comment, act_as, { weight: }) do
              on(:ok) do
                return head :no_content
              end
              on(:invalid) do
                raise Decidim::RestFull::Core::ApiException::BadRequest, "Invalid vote"
              end
            end
          end

          private

          def reject_client_credentials_mutations!
            raise Decidim::RestFull::Core::ApiException::Forbidden, "Resource owner required" if service_token?
          end

          def collection
            vis = Decidim::RestFull::Comment::CommentVisibility.visible_comments(self)
            Decidim::Comments::CommentVote.joins(:comment).merge(vis)
          end

          def find_comment_for_vote!
            cid = create_params[:comment_id]
            raise Decidim::RestFull::Core::ApiException::BadRequest, "comment_id required" if cid.blank?

            comment = Decidim::RestFull::Comment::CommentVisibility.visible_comments(self).find_by(id: cid)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Comment not found" unless comment

            comment
          end

          def create_params
            params.require(:comment_reaction).permit(:comment_id, :weight)
          end

          def vote_weight_param
            w = create_params[:weight]
            Integer(w).tap do |i|
              raise Decidim::RestFull::Core::ApiException::BadRequest, "Invalid weight" unless [1, -1].include?(i)
            end
          end

          def vote_allowed?(comment)
            Decidim::Comments::Permissions.new(
              act_as,
              Decidim::PermissionAction.new(scope: :public, action: :vote, subject: :comment),
              {
                current_organization:,
                current_component: current_component_for(comment.commentable),
                commentable: comment.root_commentable,
                comment:
              }.compact
            ).permissions.allowed?
          end

          def current_component_for(commentable)
            return commentable.component if commentable.respond_to?(:component)
            return nil unless commentable.respond_to?(:participatory_space)

            space = commentable.participatory_space
            return space if space.is_a?(Decidim::Initiative)

            nil
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
            %w(created_at)
          end

          def default_order_column
            "created_at"
          end

          def default_order_direction
            "desc"
          end

          def order
            @order ||= begin
              ord = params.permit(:order)[:order] || default_order_column
              raise Decidim::RestFull::Core::ApiException::BadRequest, "Unknown order #{ord}" unless [default_order_direction, *order_columns].include?(ord)

              ord == "rand" ? "RANDOM()" : { ord.to_s => order_direction.to_sym }
            end
          end

          def order_direction
            @order_direction ||= begin
              ord_dir = params.permit(:order_direction)[:order_direction] || default_order_direction
              raise Decidim::RestFull::Core::ApiException::BadRequest, "Unknown order direction #{ord_dir}" unless %w(asc desc).include?(ord_dir)

              ord_dir
            end
          end

          def ordered(scope)
            scope.reorder(order)
          end
        end
      end
    end
  end
end
