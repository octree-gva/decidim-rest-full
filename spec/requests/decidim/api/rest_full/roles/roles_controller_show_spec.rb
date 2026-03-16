# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Roles::RolesController do
  path "/roles/{id}" do
    get "Show role" do
      tags "Roles"
      produces "application/json"
      operationId "role"
      description "Show a single role by id (composite id from Decidim state)"
      parameter name: :id, in: :path, type: :string, required: true, description: "The composite role ID (base64url-encoded JSON of resource_type, resource_id, user_id, invited_at, type)"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Roles::RolesController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["roles"],
        permissions: ["roles.read"]
      ) do
        # Default `id` so shared examples (401/403/500) can build the request.
        let!(:default_admin_user) { create(:user, :admin, organization:) }
        let(:id) do
          Decidim::RestFull::Roles::RoleIdCodec.encode(
            resource_type: "Decidim::Organization",
            resource_id: organization.id,
            user_id: default_admin_user.id,
            invited_at: nil,
            type: "general_admin"
          )
        end

        response "200", "Role shown (general_admin)" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:role_item_response)

          let!(:admin_user) { create(:user, :admin, organization:) }
          let(:id) do
            Decidim::RestFull::Roles::RoleIdCodec.encode(
              resource_type: "Decidim::Organization",
              resource_id: organization.id,
              user_id: admin_user.id,
              invited_at: nil,
              type: "general_admin"
            )
          end

          run_test!(example_name: :general_admin_ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(id)
            expect(data["attributes"]["type"]).to eq("general_admin")
            expect(data["attributes"]["user_id"]).to eq(admin_user.id)
            expect(data["attributes"]["resource_type"]).to eq("Decidim::Organization")
            expect(data["attributes"]["resource_id"]).to eq(organization.id)
          end
        end

        response "200", "Role shown (space_administrator)" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:role_item_response)

          let!(:user) { create(:user, organization:) }
          let!(:space) { create(:participatory_process, :with_steps, organization:) }
          let!(:process_role) do
            create(:participatory_process_user_role, user:, participatory_process: space, role: "admin")
          end
          let(:id) do
            Decidim::RestFull::Roles::RoleIdCodec.encode(
              resource_type: "Decidim::ParticipatoryProcess",
              resource_id: space.id,
              user_id: user.id,
              invited_at: nil,
              type: "space_administrator"
            )
          end

          run_test!(example_name: :space_administrator_ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(id)
            expect(data["attributes"]["type"]).to eq("space_administrator")
            expect(data["attributes"]["user_id"]).to eq(user.id)
            expect(data["attributes"]["resource_type"]).to eq("Decidim::ParticipatoryProcess")
            expect(data["attributes"]["resource_id"]).to eq(space.id)
          end
        end

        response "200", "Role shown (space_moderator)" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:role_item_response)

          let!(:user) { create(:user, organization:) }
          let!(:space) { create(:participatory_process, :with_steps, organization:) }
          let!(:process_role) do
            create(:participatory_process_user_role, user:, participatory_process: space, role: "moderator")
          end
          let(:id) do
            Decidim::RestFull::Roles::RoleIdCodec.encode(
              resource_type: "Decidim::ParticipatoryProcess",
              resource_id: space.id,
              user_id: user.id,
              invited_at: nil,
              type: "space_moderator"
            )
          end

          run_test!(example_name: :space_moderator_ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(id)
            expect(data["attributes"]["type"]).to eq("space_moderator")
            expect(data["attributes"]["user_id"]).to eq(user.id)
            expect(data["attributes"]["resource_type"]).to eq("Decidim::ParticipatoryProcess")
            expect(data["attributes"]["resource_id"]).to eq(space.id)
          end
        end

        response "200", "Role shown (space_valuator)" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:role_item_response)

          let!(:user) { create(:user, organization:) }
          let!(:space) { create(:participatory_process, :with_steps, organization:) }
          let!(:process_role) do
            create(:participatory_process_user_role, user:, participatory_process: space, role: "valuator")
          end
          let(:id) do
            Decidim::RestFull::Roles::RoleIdCodec.encode(
              resource_type: "Decidim::ParticipatoryProcess",
              resource_id: space.id,
              user_id: user.id,
              invited_at: nil,
              type: "space_valuator"
            )
          end

          run_test!(example_name: :space_valuator_ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(id)
            expect(data["attributes"]["type"]).to eq("space_valuator")
            expect(data["attributes"]["user_id"]).to eq(user.id)
            expect(data["attributes"]["resource_type"]).to eq("Decidim::ParticipatoryProcess")
            expect(data["attributes"]["resource_id"]).to eq(space.id)
          end
        end

        response "200", "Role shown (space_private_member)" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:role_item_response)

          let!(:user) { create(:user, organization:) }
          let!(:space) { create(:participatory_process, :with_steps, organization:) }
          let!(:process_role) do
            create(:participatory_process_user_role, user:, participatory_process: space, role: "collaborator")
          end
          let(:id) do
            Decidim::RestFull::Roles::RoleIdCodec.encode(
              resource_type: "Decidim::ParticipatoryProcess",
              resource_id: space.id,
              user_id: user.id,
              invited_at: nil,
              type: "space_private_member"
            )
          end

          run_test!(example_name: :space_private_member_ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to eq(id)
            expect(data["attributes"]["type"]).to eq("space_private_member")
            expect(data["attributes"]["user_id"]).to eq(user.id)
            expect(data["attributes"]["resource_type"]).to eq("Decidim::ParticipatoryProcess")
            expect(data["attributes"]["resource_id"]).to eq(space.id)
          end
        end

        response "404", "Role Not Found" do
          produces "application/json"
          schema "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:error_response)

          context "when id is invalid" do
            let(:id) { "invalid" }

            run_test!
          end

          context "when role belongs to another organization" do
            let!(:other_organization) { create(:organization, available_locales: ["en"]) }
            let!(:other_admin) { create(:user, :admin, organization: other_organization) }
            let(:id) do
              Decidim::RestFull::Roles::RoleIdCodec.encode(
                resource_type: "Decidim::Organization",
                resource_id: other_organization.id,
                user_id: other_admin.id,
                invited_at: nil,
                type: "general_admin"
              )
            end

            run_test!(example_name: :not_found_other_org)
          end
        end

        it_behaves_like "unauthorized when no Bearer token"
      end
    end
  end
end
