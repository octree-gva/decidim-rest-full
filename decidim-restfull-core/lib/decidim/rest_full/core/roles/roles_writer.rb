# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      module Roles
        # Creates, updates, and destroys role state in Decidim (User admin flag,
        # ParticipatoryProcessUserRole, AssemblyUserRole, AssemblyMember) keyed by
        # the composite role id (resource_type, resource_id, user_id, invited_at, type).
        class RolesWriter
          API_TO_DECIDIM_ROLE = {
            "space_administrator" => "admin",
            "space_moderator" => "moderator",
            # Decidim 0.32 renamed valuator → evaluator; keep API type space_valuator.
            # Prefer +decidim_role_for+ at runtime — this constant keeps the 0.32 default
            # for callers that still read the hash directly.
            "space_valuator" => "evaluator",
            "space_private_member" => "collaborator"
          }.freeze

          def self.decidim_role_for(api_type)
            return valuator_role_name if api_type.to_s == "space_valuator"

            API_TO_DECIDIM_ROLE[api_type.to_s]
          end

          # Decidim 0.29 uses +"valuator"+; 0.32+ uses +"evaluator"+.
          def self.valuator_role_name
            @valuator_role_name ||= detect_valuator_role_name
          end

          def self.detect_valuator_role_name
            names = participatory_space_role_names
            return "valuator" if names.include?("valuator")
            return "evaluator" if names.include?("evaluator")

            Gem::Version.new(Decidim.version) >= Gem::Version.new("0.32.0") ? "evaluator" : "valuator"
          end

          def self.participatory_space_role_names
            return Array(Decidim::ParticipatorySpaceUser::ROLES).map(&:to_s) if defined?(Decidim::ParticipatorySpaceUser) && Decidim::ParticipatorySpaceUser.const_defined?(:ROLES)

            role_model = [
              ("Decidim::ParticipatoryProcessUserRole" if defined?(Decidim::ParticipatoryProcessUserRole)),
              ("Decidim::AssemblyUserRole" if defined?(Decidim::AssemblyUserRole))
            ].compact.first&.safe_constantize

            return Array(role_model.roles).map(&:to_s) if role_model.respond_to?(:roles)

            []
          end
          private_class_method :detect_valuator_role_name, :participatory_space_role_names

          def initialize(organization)
            @organization = organization
          end

          def create(attrs)
            validate_organization_resource!(attrs)
            case attrs[:type]
            when "general_admin"
              create_general_admin(attrs)
            when "space_administrator", "space_moderator", "space_valuator", "space_private_member"
              create_space_role(attrs)
            else
              raise ArgumentError, "Invalid role type: #{attrs[:type]}"
            end
          end

          def destroy(id)
            record = find_record(id)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Role Not Found" unless record

            case record
            when Decidim::User
              record.update!(admin: false)
            else
              record.destroy!
            end
            nil
          end

          def find_record(id)
            decoded = RoleIdCodec.decode(id)
            return nil unless decoded

            case decoded[:type]
            when "general_admin"
              find_general_admin(decoded)
            when "space_administrator", "space_moderator", "space_valuator", "space_private_member"
              find_space_role(decoded)
            end
          end

          private

          attr_reader :organization

          def decidim_role_for(api_type)
            self.class.decidim_role_for(api_type)
          end

          def validate_organization_resource!(attrs)
            return unless attrs[:resource_type] == "Decidim::Organization" && attrs[:resource_id].present?

            raise ArgumentError, "Resource must belong to current organization" if attrs[:resource_id].to_i != organization.id
          end

          def create_general_admin(attrs)
            raise ArgumentError, "general_admin requires resource_type Decidim::Organization" unless attrs[:resource_type] == "Decidim::Organization"
            raise ArgumentError, "resource_id must be current organization" unless attrs[:resource_id].to_i == organization.id

            user = Decidim::User.find_by!(organization:, id: attrs[:user_id])
            user.update!(admin: true)
            build_role_view_for_user(user)
          end

          def create_space_role(attrs)
            case attrs[:resource_type]
            when "Decidim::ParticipatoryProcess"
              create_process_role(attrs)
            when "Decidim::Assembly"
              create_assembly_role(attrs)
            when "Decidim::Conference"
              create_conference_role(attrs)
            else
              raise ArgumentError, "Unsupported resource_type for space role: #{attrs[:resource_type]}"
            end
          end

          def create_process_role(attrs)
            process = Decidim::ParticipatoryProcess.find_by!(id: attrs[:resource_id], decidim_organization_id: organization.id)
            role = decidim_role_for(attrs[:type]) || "collaborator"
            record = Decidim::ParticipatoryProcessUserRole.create!(
              participatory_process: process,
              decidim_user_id: attrs[:user_id],
              role:
            )
            build_role_view_for_process_role(record)
          end

          def create_assembly_role(attrs)
            assembly = Decidim::Assembly.find_by!(id: attrs[:resource_id], decidim_organization_id: organization.id)
            if attrs[:type] == "space_private_member"
              create_assembly_private_member(attrs, assembly)
            else
              role = decidim_role_for(attrs[:type])
              record = Decidim::AssemblyUserRole.create!(
                assembly:,
                decidim_user_id: attrs[:user_id],
                role:
              )
              build_role_view_for_assembly_user_role(record)
            end
          end

          # 0.32+: ParticipatorySpace::Member. 0.29: AssemblyUserRole collaborator
          # (AssemblyMember is a different domain — official members, not private users).
          def create_assembly_private_member(attrs, assembly)
            if defined?(Decidim::ParticipatorySpace::Member)
              user = Decidim::User.find_by!(id: attrs[:user_id], organization:)
              record = Decidim::ParticipatorySpace::Member.create!(
                participatory_space: assembly,
                user:
              )
              return build_role_view_for_assembly_member(record)
            end

            role = "collaborator"
            record = Decidim::AssemblyUserRole.create!(
              assembly:,
              decidim_user_id: attrs[:user_id],
              role:
            )
            build_role_view_for_assembly_user_role(record)
          end

          def create_conference_role(attrs)
            return create_conference_role_if_defined(attrs) if defined?(Decidim::ConferenceUserRole)

            raise ArgumentError, "Unsupported resource_type for space role: #{attrs[:resource_type]}"
          end

          def create_conference_role_if_defined(attrs)
            conference = Decidim::Conference.find_by!(id: attrs[:resource_id], decidim_organization_id: organization.id)
            role = decidim_role_for(attrs[:type]) || "collaborator"
            record = Decidim::ConferenceUserRole.create!(
              conference:,
              decidim_user_id: attrs[:user_id],
              role:
            )
            build_role_view_for_conference_user_role(record)
          end

          def find_general_admin(decoded)
            return nil unless decoded[:resource_type] == "Decidim::Organization" && decoded[:resource_id] == organization.id

            Decidim::User.find_by(organization:, id: decoded[:user_id], admin: true)
          end

          def find_space_role(decoded)
            case decoded[:resource_type]
            when "Decidim::ParticipatoryProcess"
              find_process_role(decoded)
            when "Decidim::Assembly"
              find_assembly_role(decoded)
            when "Decidim::Conference"
              find_conference_role(decoded)
            end
          end

          def find_process_role(decoded)
            return nil unless defined?(Decidim::ParticipatoryProcessUserRole)

            Decidim::ParticipatoryProcessUserRole
              .joins(:participatory_process)
              .where(decidim_participatory_processes: { decidim_organization_id: organization.id })
              .find_by(decidim_participatory_process_id: decoded[:resource_id], decidim_user_id: decoded[:user_id])
          end

          def find_assembly_role(decoded)
            return nil unless defined?(Decidim::Assembly)

            if decoded[:type] == "space_private_member"
              find_assembly_private_member(decoded)
            else
              role = decidim_role_for(decoded[:type])
              Decidim::AssemblyUserRole
                .joins(:assembly)
                .where(decidim_assemblies: { decidim_organization_id: organization.id })
                .find_by(decidim_assembly_id: decoded[:resource_id], decidim_user_id: decoded[:user_id], role:)
            end
          end

          def find_assembly_private_member(decoded)
            if decoded[:invited_at].present?
              return Decidim::AssemblyUserRole
                     .joins(:assembly)
                     .where(decidim_assemblies: { decidim_organization_id: organization.id })
                     .find_by(decidim_assembly_id: decoded[:resource_id], decidim_user_id: decoded[:user_id], role: "collaborator")
            end

            if defined?(Decidim::ParticipatorySpace::Member)
              return Decidim::ParticipatorySpace::Member.find_by(
                participatory_space_type: "Decidim::Assembly",
                participatory_space_id: decoded[:resource_id],
                decidim_user_id: decoded[:user_id]
              )
            end

            Decidim::AssemblyUserRole
              .joins(:assembly)
              .where(decidim_assemblies: { decidim_organization_id: organization.id })
              .find_by(decidim_assembly_id: decoded[:resource_id], decidim_user_id: decoded[:user_id], role: "collaborator")
          end

          def find_conference_role(decoded)
            return nil unless defined?(Decidim::ConferenceUserRole)

            role = decidim_role_for(decoded[:type])
            Decidim::ConferenceUserRole
              .joins(:conference)
              .where(decidim_conferences: { decidim_organization_id: organization.id })
              .find_by(decidim_conference_id: decoded[:resource_id], decidim_user_id: decoded[:user_id], role:)
          end

          def build_role_view_for_user(user)
            aggregator.build_role_view(
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

          def build_role_view_for_process_role(record)
            inv_at = record.user&.try(:invitation_sent_at)
            aggregator.build_role_view(
              type: RolesAggregator::SPACE_ROLE_MAP[record.role] || "space_private_member",
              resource_id: record.decidim_participatory_process_id,
              resource_type: "Decidim::ParticipatoryProcess",
              user_id: record.decidim_user_id,
              invited_at: inv_at,
              accepted_invite: record.decidim_user_id.present?,
              created_at: record.created_at,
              updated_at: record.updated_at
            )
          end

          def build_role_view_for_assembly_user_role(record)
            inv_at = record.user&.try(:invitation_sent_at)
            aggregator.build_role_view(
              type: RolesAggregator::SPACE_ROLE_MAP[record.role] || "space_private_member",
              resource_id: record.decidim_assembly_id,
              resource_type: "Decidim::Assembly",
              user_id: record.decidim_user_id,
              invited_at: inv_at,
              accepted_invite: record.decidim_user_id.present?,
              created_at: record.created_at,
              updated_at: record.updated_at
            )
          end

          def build_role_view_for_assembly_member(record)
            resource_id = record.try(:decidim_assembly_id) || record.participatory_space_id
            aggregator.build_role_view(
              type: "space_private_member",
              resource_id:,
              resource_type: "Decidim::Assembly",
              user_id: record.decidim_user_id,
              invited_at: nil,
              accepted_invite: true,
              created_at: record.created_at,
              updated_at: record.updated_at
            )
          end

          def build_role_view_for_conference_user_role(record)
            inv_at = record.user&.try(:invitation_sent_at)
            aggregator.build_role_view(
              type: RolesAggregator::SPACE_ROLE_MAP[record.role] || "space_private_member",
              resource_id: record.decidim_conference_id,
              resource_type: "Decidim::Conference",
              user_id: record.decidim_user_id,
              invited_at: inv_at,
              accepted_invite: record.decidim_user_id.present?,
              created_at: record.created_at,
              updated_at: record.updated_at
            )
          end

          def aggregator
            @aggregator ||= RolesAggregator.new(organization)
          end
        end
      end
    end
  end
end
