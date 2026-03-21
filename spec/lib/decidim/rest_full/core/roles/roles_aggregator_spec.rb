# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    module Core
      module Roles
        RSpec.describe RolesAggregator do
          describe "SPACE_ROLE_MAP" do
            it "maps Decidim roles to API types" do
              expect(described_class::SPACE_ROLE_MAP["admin"]).to eq("space_administrator")
              expect(described_class::SPACE_ROLE_MAP["moderator"]).to eq("space_moderator")
              expect(described_class::SPACE_ROLE_MAP["valuator"]).to eq("space_valuator")
              expect(described_class::SPACE_ROLE_MAP["collaborator"]).to eq("space_private_member")
            end
          end

          describe ".for_organization" do
            it "returns role views and includes general_admin for admin users" do
              organization = create(:organization, available_locales: ["en"])
              admin = create(:user, :admin, organization:)
              roles = described_class.for_organization(organization)
              expect(roles).to be_an(Array)
              expect(roles.first).to be_a(described_class::RoleView) if roles.any?
              general = roles.find { |r| r.type == "general_admin" && r.user_id == admin.id }
              expect(general).to be_present
              expect(RoleIdCodec.decode(general.id)[:user_id]).to eq(admin.id)
            end

            it "find_by_id returns the role when id is valid" do
              organization = create(:organization, available_locales: ["en"])
              admin = create(:user, :admin, organization:)
              aggregator = described_class.new(organization)
              id = RoleIdCodec.encode(
                resource_type: "Decidim::Organization",
                resource_id: organization.id,
                user_id: admin.id,
                invited_at: nil,
                type: "general_admin"
              )
              role = aggregator.find_by(id:)
              expect(role).to be_present
              expect(role.type).to eq("general_admin")
              expect(role.user_id).to eq(admin.id)
            end
          end
        end
      end
    end
  end
end
