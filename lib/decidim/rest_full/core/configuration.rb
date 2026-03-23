# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class Configuration
        include ActiveSupport::Configurable

        config_accessor :loadbalancer_ips do
          ips = ENV.fetch("DECIDIM_REST_LOADBALANCER_IPS", "127.0.0.1, ::1").split(",").map(&:strip)
          ips.map { |ip| IPAddr.new(ip) }.map(&:to_s)
        end

        config_accessor :queue_name do
          ENV.fetch("DECIDIM_REST_QUEUE_NAME", "default")
        end

        config_accessor :docs_url do
          ENV.fetch("DOCS_URL", "https://octree-gva.github.io/decidim-rest-full")
        end

        # When false, Proposals engine does not mount proposal API routes or apply proposal overrides.
        config_accessor :enable_proposals_api do
          true
        end

        # When false, Blogs engine does not mount comment API routes.
        config_accessor :enable_comments_api do
          true
        end

        # When false, Blogs engine does not mount blog API routes.
        config_accessor :enable_blogs_api do
          true
        end

        config_accessor :available_permissions do
          {
            "blogs" => [
              "blogs.read"
            ],
            "comments" => [
              "comments.read",
              "comments.create",
              "comments.update",
              "comments.destroy",
              "comments.vote",
              "comments.moderate",
              *config.events_for_comments
            ],
            "system" => [
              "oauth.impersonate",
              "oauth.login",
              "system.organizations.read",
              "system.organizations.update",
              "system.organizations.destroy",
              "system.organizations.extended_data.read",
              "system.organizations.extended_data.update",
              *config.events_for_system
            ],
            "public" => [
              "public.component.read",
              "public.space.read"
            ],
            "proposal" => [
              "proposals.read", "proposals.draft", "proposals.vote",
              *config.events_for_proposals
            ],
            "oauth" => [
              "oauth.magic_link",
              "oauth.extended_data.read",
              "oauth.extended_data.update",
              *config.events_for_oauth
            ]
          }
        end

        config_accessor :events_for_proposals do
          [
            "draft_proposal_creation.succeeded",
            "draft_proposal_update.succeeded",
            "proposal_creation.succeeded",
            "proposal_update.succeeded",
            "proposal_state_change.succeeded"
          ]
        end

        config_accessor :events_for_oauth do
          [
            "user.created",
            "user.updated"
          ]
        end

        config_accessor :events_for_system do
          [
            "system.organizations.created",
            "system.organizations.updated",
            "system.organizations.deleted"
          ]
        end

        config_accessor :events_for_comments do
          [
            "comment_creation.succeeded",
            "comment_update.succeeded"
          ]
        end
      end
    end
  end
end
