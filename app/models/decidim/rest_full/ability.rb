# frozen_string_literal: true

require "cancan"

module Decidim
  module RestFull
    class Ability
      include ::CanCan::Ability
      attr_reader :api_client, :permissions

      def initialize(api_client, scopes = nil)
        return unless api_client

        @api_client = api_client
        @permissions = api_client.permission_strings

        can :impersonate, Decidim::RestFull::ApiClient if permissions.include? "oauth.impersonate"
        can :login, Decidim::RestFull::ApiClient if permissions.include? "oauth.login"
        # Switch scopes and compose permissions
        scopes = api_client.scopes.to_a if scopes.nil?
        perms_for_public if scopes.include? "public"
        perms_for_system if scopes.include? "system"
        perms_for_proposals if scopes.include? "proposals"
        perms_for_blogs if scopes.include? "blogs"
      end

      def self.from_doorkeeper_token(doorkeeper_token)
        return Decidim::RestFull::Ability.new(nil) unless doorkeeper_token && doorkeeper_token.valid?

        application = doorkeeper_token.application
        return Decidim::RestFull::Ability.new(nil) unless application.is_a? Decidim::RestFull::ApiClient

        application_scopes = application.scopes
        # Check if token is using allowed scopes from the client id
        unallowed_scopes = doorkeeper_token.scopes.to_a - application_scopes.to_a
        return Decidim::RestFull::Ability.new(nil) if unallowed_scopes.any?

        Decidim::RestFull::Ability.new(doorkeeper_token.application)
      end

      private

      def perms_for_public
        can :read, ::Decidim::ParticipatorySpaceManifest if permissions.include? "public.space.read"
        can :read, ::Decidim::Component if permissions.include? "public.component.read"
      end

      def perms_for_system
        can :read, ::Decidim::Organization if permissions.include? "system.organizations.read"
        can :read, ::Decidim::User if permissions.include? "system.users.read"
        can :read_extended_data, ::Decidim::User if permissions.include? "system.users.extended_data.read"
        can :update_extended_data, ::Decidim::User if permissions.include? "system.users.extended_data.update"
      end

      def perms_for_blogs
        can :read, ::Decidim::Blogs::Post if permissions.include? "blogs.read"
      end

      def perms_for_proposals
        can :read, ::Decidim::Proposals::Proposal if permissions.include? "proposals.read"
        can :draft, ::Decidim::Proposals::Proposal if permissions.include? "proposals.draft"
      end
    end
  end
end
