# frozen_string_literal: true

require_relative "helpers/resource_links_helper"

module Decidim
  module Api
    module RestFull
      class MagicLinkSerializer < ApplicationSerializer
        extend Helpers::ResourceLinksHelper

        attribute :token, &:magic_token
        attribute :label do |_object|
          "My label"
        end
        link :self do |_object, params|
          {
            href: link_join(params[:host], "me", "magic_links"),
            title: "Generates a magic link",
            rel: "resource",
            meta: {
              action_method: "POST",
              action_enctype: "application/x-www-form-urlencoded"
            }
          }
        end
        link :sign_in do |object, params|
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
