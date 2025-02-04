# frozen_string_literal: true

require_relative "helpers/resource_links_helper"

module Decidim
  module Api
    module RestFull
      class MagicLinkRedirectSerializer < ApplicationSerializer
        extend Helpers::ResourceLinksHelper

        attribute :label do |_object|
          "You are beeing redirected."
        end
        attribute :redirect_url do |_object, params|
          ::Decidim::Core::Engine.routes.url_helpers.root_url(host: params[:host])
        end
        link :magic_link do |_object, params|
          {
            href: link_join(params[:host], "me", "magic_links"),
            title: "Generates a magic link ",
            rel: "resource",
            meta: {
              action_method: "POST",
              action_enctype: "application/x-www-form-urlencoded"
            }
          }
        end
        link :self do |object, params|
          {
            href: link_join(params[:host], "me", "magic_links", object.magic_token),
            title: "Sign in with magic link",
            rel: "resource",
            meta: {
              action_method: "GET"
            }
          }
        end
      end
    end
  end
end
