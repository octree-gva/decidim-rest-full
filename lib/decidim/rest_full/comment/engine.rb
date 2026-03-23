# frozen_string_literal: true

module Decidim
  module RestFull
    module Comment
      class Engine < ::Rails::Engine
        config.root = Pathname.new(File.expand_path("../../../..", __dir__))

        config.to_prepare do
          next unless Decidim::RestFull::Core::Configuration.enable_comments_api

          Decidim::RestFull::Comment::CommentRansackers.register!
          require "decidim/comments/create_comment"
          require "decidim/rest_full/comment/overrides/create_comment_override"
        end

        initializer "rest_full.comment.webhooks" do
          next unless Decidim::RestFull::Core::Configuration.enable_comments_api

          %w(
            decidim.comments.create_comment:after
            decidim.comments.update_comment:after
          ).each do |notification_name|
            ActiveSupport::Notifications.subscribe(notification_name) do |_name, _start, _finish, _id, payload|
              next if payload.nil?

              resource = payload[:resource]
              next unless resource.is_a?(Decidim::Comments::Comment)

              org = resource.organization
              next if org.nil?

              event = Decidim::RestFull::Comment::WebhookSubscription.event_name_for(notification_name)
              next if event.blank?

              Decidim::RestFull::Comment::CommentWebhookJob.perform_later(event, resource.id, org.id)
            end
          end
        end

        initializer "rest_full.comment.permissions" do
          next unless Decidim::RestFull::Core::Configuration.enable_comments_api

          registry = Decidim::RestFull::Core::PermissionRegistry
          registry.register(:comments, "comments.read", group: :comments)
          registry.register(:comments, "comments.create", group: :comments)
          registry.register(:comments, "comments.update", group: :comments)
          registry.register(:comments, "comments.destroy", group: :comments)
          registry.register(:comments, "comments.vote", group: :comments)
          registry.register(:comments, "comments.moderate", group: :comments)
        end

        initializer "rest_full.comment.routes" do
          Decidim::RestFull::Core::RouteRegistry.draw_api_routes do
            constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_comments_api }) do
              resources :comments,
                        only: [:index, :show, :create, :update, :destroy],
                        controller: "/decidim/api/rest_full/comment/comments" do
                member do
                  post :hide, action: :hide
                end
              end

              resources :comment_reactions,
                        only: [:index, :create],
                        controller: "/decidim/api/rest_full/comment/comment_reactions"
            end
          end
        end
      end
    end
  end
end
