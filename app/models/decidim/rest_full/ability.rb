# frozen_string_literal: true

require "cancan"

module Decidim
  module RestFull
    class Ability
      include ::CanCan::Ability
      attr_reader :api_client, :permissions

      def initialize(api_client)
        return unless api_client

        @api_client = api_client
        @permissions = api_client.permission_strings

        can :impersonate, Decidim::RestFull::ApiClient if permissions.include? "oauth.impersonate"
        can :login, Decidim::RestFull::ApiClient if permissions.include? "oauth.login"
        # Switch scopes and compose permissions
        scopes = api_client.scopes.to_a
        perms_for_public if scopes.include? "public"
        perms_for_system if scopes.include? "system"
        perms_for_proposals if scopes.include? "proposals"
      end

      def self.from_doorkeeper_token(doorkeeper_token)
        return Decidim::RestFull::Ability.new(nil) unless doorkeeper_token && doorkeeper_token.valid?
        return Decidim::RestFull::Ability.new(nil) unless doorkeeper_token.application.is_a? Decidim::RestFull::ApiClient

        Decidim::RestFull::Ability.new(doorkeeper_token.application)
      end

      private

      def perms_for_public; end

      def perms_for_system
        can :read, ::Decidim::Organization if permissions.include? "system.organizations.read"
        can :read, ::Decidim::User if permissions.include? "system.users.read"
      end

      def perms_for_proposals; end
    end
  end
end
