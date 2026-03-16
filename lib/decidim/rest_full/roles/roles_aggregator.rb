# frozen_string_literal: true

module Decidim
  module RestFull
    module Roles
      # Builds a read-only list of "roles" from current Decidim state:
      # - general_admin from User with admin: true in the organization
      # - space_* from ParticipatoryProcessUserRole, AssemblyUserRole (admin→space_administrator, etc.)
      # - space_private_member from AssemblyMember (user-linked members)
      class RolesAggregator
        SPACE_ROLE_MAP = {
          "admin" => "space_administrator",
          "moderator" => "space_moderator",
          "valuator" => "space_valuator",
          "collaborator" => "space_private_member"
        }.freeze

        RoleView = Struct.new(:id, :type, :resource_id, :resource_type, :user_id, :invited_at, :accepted_invite, :created_at, :updated_at, keyword_init: true)

        def self.for_organization(organization)
          new(organization).call
        end

        def initialize(organization)
          @organization = organization
        end

        def call
          roles = []
          roles.concat(general_admin_roles)
          roles.concat(participatory_process_roles)
          roles.concat(assembly_user_roles)
          roles.concat(assembly_member_roles)
          roles.concat(conference_user_roles)
          roles
        end

        def find_by(id:)
          find_by_id(id)
        end

        def find_by_id(id)
          decoded = RoleIdCodec.decode(id)
          call.find { |r| match_decoded?(r, decoded) }
        end

        def build_role_view(attrs)
          type = attrs[:type]
          resource_id = attrs[:resource_id]
          resource_type = attrs[:resource_type]
          user_id = attrs[:user_id]
          invited_at = attrs[:invited_at]
          accepted_invite = attrs[:accepted_invite]
          created_at = attrs[:created_at]
          updated_at = attrs[:updated_at]
          norm_inv = RoleIdCodec.normalize_invited_at(invited_at)
          id = RoleIdCodec.encode(
            resource_type:,
            resource_id:,
            user_id:,
            invited_at: norm_inv,
            type:
          )
          RoleView.new(
            id:,
            type:,
            resource_id:,
            resource_type:,
            user_id:,
            invited_at: invited_at.respond_to?(:iso8601) ? invited_at.iso8601 : invited_at,
            accepted_invite:,
            created_at:,
            updated_at:
          )
        end

        private

        attr_reader :organization

        def general_admin_roles
          Decidim::User.where(organization:, admin: true).map do |user|
            build_role_view(
              type: "general_admin",
              resource_id: organization.id,
              resource_type: "Decidim::Organization",
              user_id: user.id,
              invited_at: nil,
              accepted_invite: true,
              created_at: user.created_at,
              updated_at: user.updated_at
            )
          end
        end

        def participatory_process_roles
          return [] unless defined?(Decidim::ParticipatoryProcessUserRole)

          Decidim::ParticipatoryProcessUserRole
            .joins(:participatory_process)
            .where(decidim_participatory_processes: { decidim_organization_id: organization.id })
            .includes(:user, :participatory_process)
            .map do |record|
              inv_at = record.user&.try(:invitation_sent_at)
              build_role_view(
                type: SPACE_ROLE_MAP[record.role] || "space_private_member",
                resource_id: record.decidim_participatory_process_id,
                resource_type: "Decidim::ParticipatoryProcess",
                user_id: record.decidim_user_id,
                invited_at: inv_at,
                accepted_invite: record.decidim_user_id.present?,
                created_at: record.created_at,
                updated_at: record.updated_at
              )
            end
        end

        def assembly_user_roles
          return [] unless defined?(Decidim::AssemblyUserRole)

          Decidim::AssemblyUserRole
            .joins(:assembly)
            .where(decidim_assemblies: { decidim_organization_id: organization.id })
            .includes(:user, :assembly)
            .map do |record|
              inv_at = record.user&.try(:invitation_sent_at)
              build_role_view(
                type: SPACE_ROLE_MAP[record.role] || "space_private_member",
                resource_id: record.decidim_assembly_id,
                resource_type: "Decidim::Assembly",
                user_id: record.decidim_user_id,
                invited_at: inv_at,
                accepted_invite: record.decidim_user_id.present?,
                created_at: record.created_at,
                updated_at: record.updated_at
              )
            end
        end

        def assembly_member_roles
          return [] unless defined?(Decidim::AssemblyMember)

          Decidim::AssemblyMember
            .joins(:assembly)
            .where(decidim_assemblies: { decidim_organization_id: organization.id })
            .where.not(decidim_user_id: nil)
            .not_ceased
            .includes(:user, :assembly)
            .map do |record|
              build_role_view(
                type: "space_private_member",
                resource_id: record.decidim_assembly_id,
                resource_type: "Decidim::Assembly",
                user_id: record.decidim_user_id,
                invited_at: nil,
                accepted_invite: true,
                created_at: record.created_at,
                updated_at: record.updated_at
              )
            end
        end

        def conference_user_roles
          return [] unless defined?(Decidim::ConferenceUserRole)

          Decidim::ConferenceUserRole
            .joins(:conference)
            .where(decidim_conferences: { decidim_organization_id: organization.id })
            .includes(:user, :conference)
            .map do |record|
              inv_at = record.user&.try(:invitation_sent_at)
              build_role_view(
                type: SPACE_ROLE_MAP[record.role] || "space_private_member",
                resource_id: record.decidim_conference_id,
                resource_type: "Decidim::Conference",
                user_id: record.decidim_user_id,
                invited_at: inv_at,
                accepted_invite: record.decidim_user_id.present?,
                created_at: record.created_at,
                updated_at: record.updated_at
              )
            end
        end

        def match_decoded?(role, decoded)
          return false unless decoded

          norm_role_inv = RoleIdCodec.normalize_invited_at(role.invited_at)
          decoded_inv = decoded[:invited_at]
          decoded_inv = nil if decoded_inv.blank?
          role.resource_type == decoded[:resource_type] &&
            role.resource_id == decoded[:resource_id] &&
            role.user_id == decoded[:user_id] &&
            norm_role_inv == decoded_inv &&
            role.type == decoded[:type]
        end
      end
    end
  end
end
