# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Roles::RolesController do
  path "/roles/{id}" do
    delete "Destroy role" do
      tags "Roles"
      produces "application/json"
      operationId "destroyRole"
      description "Remove a role (revoke admin, or delete ParticipatoryProcessUserRole/AssemblyUserRole/AssemblyMember). Id is the composite encoded id."
      parameter name: :id, in: :path, type: :string, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Roles::RolesController,
        action: :destroy,
        security_types: [:credentialFlow],
        scopes: ["roles"],
        permissions: ["roles.read", "roles.write"]
      ) do
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

        response "204", "Role destroyed" do
          run_test!(example_name: :ok) do |_example|
            # rswag exposes the current response via the `response` helper.
            expect(response).to have_http_status(:no_content)
            expect(Decidim::ParticipatoryProcessUserRole.exists?(process_role.id)).to be false
          end
        end

        response "404", "Role Not Found" do
          let(:id) { "eyJyZXNvdXJjZV90eXBlIjoiRm9vIn0" }

          run_test!(example_name: :not_found)
        end
      end
    end
  end
end
