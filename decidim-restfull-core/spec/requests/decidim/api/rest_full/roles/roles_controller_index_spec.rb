# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Roles::RolesController do
  path "/roles" do
    get "List roles" do
      tags "Roles"
      produces "application/json"
      operationId "listRoles"
      description "List roles scoped to the current organization (from Decidim state: admin users, participatory space roles, assembly members)"
      it_behaves_like "paginated params"
      it_behaves_like "filtered params", filter: "user_id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered params", filter: "resource_id", item_schema: { type: :integer }, only: :integer
      it_behaves_like "filtered params", filter: "resource_type", item_schema: { type: :string }, only: :string
      it_behaves_like "filtered params", filter: "type", item_schema: { type: :string }, only: :string

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Roles::RolesController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["roles"],
        permissions: ["roles.read"]
      ) do
        response "200", "Roles listed" do
          consumes "application/json"
          produces "application/json"
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:role_index_response)

          let(:page) { 1 }
          let(:per_page) { 50 }

          let!(:admin_user) { create(:user, :admin, organization:) }
          let!(:space) { create(:participatory_process, :with_steps, organization:) }
          let!(:process_role) do
            create(:participatory_process_user_role, user: admin_user, participatory_process: space, role: "admin")
          end

          let!(:other_organization) { create(:organization, available_locales: ["en"]) }
          let!(:other_admin) { create(:user, :admin, organization: other_organization) }

          context "without filters" do
            run_test!(example_name: :ok) do |example|
              data = JSON.parse(example.body)["data"]
              ids = data.map { |item| item["id"] }
              types = data.map { |item| item["attributes"]["type"] }
              admin_role_id = Decidim::RestFull::Core::Roles::RoleIdCodec.encode(
                resource_type: "Decidim::Organization",
                resource_id: organization.id,
                user_id: admin_user.id,
                invited_at: nil,
                type: "general_admin"
              )
              process_role_id = Decidim::RestFull::Core::Roles::RoleIdCodec.encode(
                resource_type: "Decidim::ParticipatoryProcess",
                resource_id: space.id,
                user_id: admin_user.id,
                invited_at: nil,
                type: "space_administrator"
              )
              other_admin_id = Decidim::RestFull::Core::Roles::RoleIdCodec.encode(
                resource_type: "Decidim::Organization",
                resource_id: other_organization.id,
                user_id: other_admin.id,
                invited_at: nil,
                type: "general_admin"
              )

              expect(ids).to include(admin_role_id, process_role_id)
              expect(types).to include("general_admin", "space_administrator")
              expect(ids).not_to include(other_admin_id)
            end
          end

          context "with filter[user_id_eq]" do
            let(:"filter[user_id_eq]") { admin_user.id }

            run_test!(example_name: :filter_by_user_id) do |example|
              data = JSON.parse(example.body)["data"]
              user_ids = data.map { |item| item["attributes"]["user_id"] }.compact

              expect(user_ids.uniq).to eq([admin_user.id])
            end
          end

          context "with filter[resource_type_eq]" do
            let(:"filter[resource_type_eq]") { "Decidim::ParticipatoryProcess" }

            run_test!(example_name: :filter_by_resource_type) do |example|
              data = JSON.parse(example.body)["data"]
              resource_types = data.map { |item| item["attributes"]["resource_type"] }.uniq

              expect(resource_types).to eq(["Decidim::ParticipatoryProcess"])
            end
          end

          context "with filter[type_eq]" do
            let(:"filter[type_eq]") { "space_administrator" }

            run_test!(example_name: :filter_by_type) do |example|
              data = JSON.parse(example.body)["data"]
              types = data.map { |item| item["attributes"]["type"] }.compact

              expect(types.uniq).to eq(["space_administrator"])
            end
          end

          context "with filter[resource_type_eq], filter[resource_id_eq] and filter[type_eq] (participatory space + space_administrator)" do
            let(:"filter[resource_type_eq]") { "Decidim::ParticipatoryProcess" }
            let(:"filter[resource_id_eq]") { space.id }
            let(:"filter[type_eq]") { "space_administrator" }

            run_test!(example_name: :filter_by_participatory_space_and_type) do |example|
              data = JSON.parse(example.body)["data"]
              expect(data.size).to eq(1)
              expect(data.first["attributes"]["type"]).to eq("space_administrator")
              expect(data.first["attributes"]["resource_type"]).to eq("Decidim::ParticipatoryProcess")
              expect(data.first["attributes"]["resource_id"]).to eq(space.id)
            end
          end
        end

        it_behaves_like "unauthorized when no Bearer token"
      end
    end
  end
end
