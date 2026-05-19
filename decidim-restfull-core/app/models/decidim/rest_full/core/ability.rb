# frozen_string_literal: true

require "cancan"

module Decidim
  module RestFull
    module Core
      class Ability
        include ::CanCan::Ability
        attr_reader :api_client, :permissions

        def initialize(api_client, scopes = nil)
          return unless api_client

          @api_client = api_client
          @permissions = api_client.permission_strings

          can :impersonate, Decidim::RestFull::Core::ApiClient if permissions.include? "oauth.impersonate"
          can :login, Decidim::RestFull::Core::ApiClient if permissions.include? "oauth.login"
          # Switch scopes and compose permissions
          scopes = api_client.scopes.to_a if scopes.nil?
          apply_permissions!(scopes)
        end

        def apply_permissions!(scopes)
          [
            ["oauth", :perms_for_users],
            ["public", :perms_for_public],
            ["system", :perms_for_system],
            ["proposals", :perms_for_proposals],
            ["meetings", :perms_for_meetings],
            ["debates", :perms_for_debates],
            ["blogs", :perms_for_blogs],
            ["budgets", :perms_for_budgets],
            ["surveys", :perms_for_surveys],
            ["accountability", :perms_for_accountability],
            ["sortitions", :perms_for_sortitions],
            ["roles", :perms_for_roles],
            ["attachments", :perms_for_attachments]
          ].each do |scope_token, meth|
            send(meth) if scopes.include?(scope_token)
          end
        end

        def self.from_doorkeeper_token(doorkeeper_token)
          return Decidim::RestFull::Core::Ability.new(nil) unless doorkeeper_token && doorkeeper_token.valid?

          application = doorkeeper_token.application
          return Decidim::RestFull::Core::Ability.new(nil) unless application.is_a? Decidim::RestFull::Core::ApiClient

          application_scopes = application.scopes
          # Check if token is using allowed scopes from the client id
          unallowed_scopes = doorkeeper_token.scopes.to_a - application_scopes.to_a
          return Decidim::RestFull::Core::Ability.new(nil) if unallowed_scopes.any?

          Decidim::RestFull::Core::Ability.new(doorkeeper_token.application)
        end

        private

        def perms_for_users
          can :magic_link, ::Decidim::User if permissions.include? "oauth.magic_link"
          can :read_extended_data, ::Decidim::User if permissions.include? "oauth.extended_data.read"
          can :update_extended_data, ::Decidim::User if permissions.include? "oauth.extended_data.update"
          can :read, ::Decidim::User if permissions.include? "oauth.read"
        end

        def perms_for_public
          can :read, ::Decidim::ParticipatorySpaceManifest if permissions.include? "public.space.read"
          can :read, ::Decidim::Component if permissions.include? "public.component.read"
        end

        def perms_for_system
          can :create, ::Decidim::Organization if permissions.include? "system.organizations.create"
          can :read, ::Decidim::Organization if permissions.include? "system.organizations.read"
          can :update, ::Decidim::Organization if permissions.include? "system.organizations.update"
          can :destroy, ::Decidim::Organization if permissions.include? "system.organizations.destroy"

          can :read_extended_data, ::Decidim::Organization if permissions.include? "system.organization.extended_data.read"
          can :update_extended_data, ::Decidim::Organization if permissions.include? "system.organization.extended_data.update"
        end

        def perms_for_blogs
          return unless defined?(::Decidim::Blogs::Post)

          can :read, ::Decidim::Blogs::Post if permissions.include? "blogs.read"
          if permissions.include?("blogs.write")
            can :create, ::Decidim::Blogs::Post
            can :update, ::Decidim::Blogs::Post
          end
          can :destroy, ::Decidim::Blogs::Post if permissions.include? "blogs.destroy"
        end

        def perms_for_roles
          can :read, :role if permissions.include? "roles.read"
          if permissions.include? "roles.write"
            can :create, :role
            can :destroy, :role
          end
        end

        def perms_for_attachments
          can :read, ::Decidim::Attachment if permissions.include? "attachments.read"
          if permissions.include?("attachments.write")
            can :create, ::Decidim::Attachment
            can :update, ::Decidim::Attachment
          end
          can :destroy, ::Decidim::Attachment if permissions.include? "attachments.destroy"
        end

        def perms_for_proposals
          return unless defined?(::Decidim::Proposals::Proposal)

          can :read, ::Decidim::Proposals::Proposal if permissions.include? "proposals.read"
          can :draft, ::Decidim::Proposals::Proposal if permissions.include? "proposals.draft"
          if permissions.include? "proposals.vote"
            can :vote, ::Decidim::Proposals::Proposal
            can :unvote, ::Decidim::Proposals::Proposal
          end
        end

        def perms_for_meetings
          return unless defined?(::Decidim::Meetings::Meeting)

          can :read, ::Decidim::Meetings::Meeting if permissions.include? "meetings.read"
        end

        def perms_for_debates
          return unless defined?(::Decidim::Debates::Debate)

          can :read, ::Decidim::Debates::Debate if permissions.include? "debates.read"
        end

        def perms_for_budgets
          return unless defined?(::Decidim::Budgets::Budget)

          can :read, ::Decidim::Budgets::Budget if permissions.include? "budgets.read"
        end

        def perms_for_surveys
          return unless defined?(::Decidim::Surveys::Survey)

          can :read, ::Decidim::Surveys::Survey if permissions.include?("surveys.read")
          perms_for_surveys_forms
        end

        def perms_for_surveys_forms
          return unless defined?(::Decidim::Forms::Questionnaire)

          can :read, ::Decidim::Forms::Questionnaire if permissions.include?("surveys.questionnaires.read")
          can :submit, ::Decidim::Forms::Questionnaire if permissions.include?("surveys.answers.submit")
          can :manage, ::Decidim::Forms::Question if defined?(::Decidim::Forms::Question) && permissions.include?("surveys.questions.manage")
          return unless defined?(::Decidim::Forms::Answer)

          can :read, ::Decidim::Forms::Answer if permissions.include?("surveys.answers.read")
          can :destroy, ::Decidim::Forms::Answer if permissions.include?("surveys.answers.destroy")
        end

        def perms_for_accountability
          return unless defined?(::Decidim::Accountability::Result)

          can :read, ::Decidim::Accountability::Result if permissions.include? "accountability.read"
        end

        def perms_for_sortitions
          return unless defined?(::Decidim::Sortitions::Sortition)

          can :read, ::Decidim::Sortitions::Sortition if permissions.include? "sortitions.read"
        end
      end
    end
  end
end
