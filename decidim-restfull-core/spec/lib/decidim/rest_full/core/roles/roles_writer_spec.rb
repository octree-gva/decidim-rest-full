# frozen_string_literal: true

require "spec_helper"

module Decidim
  module RestFull
    module Core
      module Roles
        RSpec.describe RolesWriter do
          describe "API_TO_DECIDIM_ROLE" do
            it "maps API types to Decidim roles" do
              expect(described_class::API_TO_DECIDIM_ROLE["space_administrator"]).to eq("admin")
              expect(described_class::API_TO_DECIDIM_ROLE["space_moderator"]).to eq("moderator")
              expect(described_class::API_TO_DECIDIM_ROLE["space_private_member"]).to eq("collaborator")
              expect(described_class.valuator_role_name).to be_in(%w(valuator evaluator))
              expect(described_class.decidim_role_for("space_valuator")).to eq(described_class.valuator_role_name)
            end
          end

          describe "#create" do
            it "raises ArgumentError for invalid role type" do
              organization = create(:organization, available_locales: ["en"])
              user = create(:user, organization:)
              writer = described_class.new(organization)
              attrs = {
                resource_type: "Decidim::Organization",
                resource_id: organization.id,
                user_id: user.id,
                type: "invalid_type"
              }
              expect { writer.create(attrs) }.to raise_error(ArgumentError, /Invalid role type/)
            end
          end
        end
      end
    end
  end
end
