# frozen_string_literal: true

require "swagger_helper"

RSpec.describe Decidim::Api::RestFull::Roles::RolesController do
  path "/roles/sync" do
    post "Create role" do
      tags "Roles"
      produces "application/json"
      consumes "application/json"
      operationId "createRole"
      description "Create a role (general_admin or space_*). Mutates Decidim state (User admin, ParticipatoryProcessUserRole, AssemblyUserRole, AssemblyMember)."
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              attributes: {
                type: :object,
                properties: {
                  resource_type: { type: :string, enum: Decidim.participatory_space_registry.manifests.map { |space| space.model_class_name.to_s } + ["Decidim::Organization"] },
                  resource_id: { type: :integer },
                  user_id: { type: :integer },
                  type: { type: :string, enum: %w(general_admin space_private_member space_administrator space_moderator space_valuator) }
                },
                required: %w(resource_type resource_id user_id type)
              }
            },
            required: [:attributes]
          }
        },
        required: [:data]
      }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Roles::RolesController,
        action: :create_sync,
        security_types: [:credentialFlow],
        scopes: ["roles"],
        permissions: ["roles.read", "roles.write"]
      ) do
        let!(:user) { create(:user, organization:) }
        let!(:space) { create(:participatory_process, :with_steps, organization:) }
        # Default body so shared examples (401/403/500) can build the request.
        let(:body) do
          {
            data: {
              attributes: {
                resource_type: "Decidim::Organization",
                resource_id: organization.id,
                user_id: user.id,
                type: "general_admin"
              }
            }
          }
        end

        [:participatory_processes, :assemblies, :conferences].each do |space_manifest|
          manifest = Decidim.participatory_space_registry.manifests.find { |m| m.name == space_manifest }
          next unless manifest

          factory_name = space_manifest.to_s.singularize.to_sym
          model_class_name = manifest.model_class_name.to_s

          context "when space is #{space_manifest}" do
            before do
              skip "#{space_manifest} factory not available" unless FactoryBot.factories.registered?(factory_name)
            end

            let(:space_factory_traits) { space_manifest == :participatory_processes ? [:with_steps] : [] }
            let!(:space) { create(factory_name, *space_factory_traits, organization:) }

            response "201", "Role created (space_administrator) - #{space_manifest}" do
              let(:body) do
                {
                  data: {
                    attributes: {
                      resource_type: model_class_name,
                      resource_id: space.id,
                      user_id: user.id,
                      type: "space_administrator"
                    }
                  }
                }
              end

              run_test!(example_name: :"space_administrator_ok_#{space_manifest}") do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"]).to be_present
                expect(data["attributes"]["type"]).to eq("space_administrator")
                expect(data["attributes"]["resource_type"]).to eq(model_class_name)
                expect(data["attributes"]["resource_id"]).to eq(space.id)
                expect(data["attributes"]["user_id"]).to eq(user.id)
                space.reload
                new_role = space.user_roles.find_by(decidim_user_id: user.id)
                expect(new_role).to be_present
                expect(new_role.role).to eq("admin")
              end
            end

            response "201", "Role created (space_moderator) - #{space_manifest}" do
              let(:body) do
                {
                  data: {
                    attributes: {
                      resource_type: model_class_name,
                      resource_id: space.id,
                      user_id: user.id,
                      type: "space_moderator"
                    }
                  }
                }
              end

              run_test!(example_name: :"space_moderator_ok_#{space_manifest}") do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"]).to be_present
                expect(data["attributes"]["type"]).to eq("space_moderator")
                expect(data["attributes"]["resource_type"]).to eq(model_class_name)
                expect(data["attributes"]["resource_id"]).to eq(space.id)
                expect(data["attributes"]["user_id"]).to eq(user.id)
                space.reload
                new_role = space.user_roles.find_by(decidim_user_id: user.id)
                expect(new_role).to be_present
                expect(new_role.role).to eq("moderator")
              end
            end

            response "201", "Role created (space_valuator) - #{space_manifest}" do
              let(:body) do
                {
                  data: {
                    attributes: {
                      resource_type: model_class_name,
                      resource_id: space.id,
                      user_id: user.id,
                      type: "space_valuator"
                    }
                  }
                }
              end

              run_test!(example_name: :"space_valuator_ok_#{space_manifest}") do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"]).to be_present
                expect(data["attributes"]["type"]).to eq("space_valuator")
                expect(data["attributes"]["resource_type"]).to eq(model_class_name)
                expect(data["attributes"]["resource_id"]).to eq(space.id)
                expect(data["attributes"]["user_id"]).to eq(user.id)
                space.reload
                new_role = space.user_roles.find_by(decidim_user_id: user.id)
                expect(new_role).to be_present
                expect(new_role.role).to eq("valuator")
              end
            end

            response "201", "Role created (space_private_member) - #{space_manifest}" do
              let(:body) do
                {
                  data: {
                    attributes: {
                      resource_type: model_class_name,
                      resource_id: space.id,
                      user_id: user.id,
                      type: "space_private_member"
                    }
                  }
                }
              end

              run_test!(example_name: :"space_private_member_ok_#{space_manifest}") do |example|
                data = JSON.parse(example.body)["data"]
                expect(data["id"]).to be_present
                expect(data["attributes"]["type"]).to eq("space_private_member")
                expect(data["attributes"]["resource_type"]).to eq(model_class_name)
                expect(data["attributes"]["resource_id"]).to eq(space.id)
                expect(data["attributes"]["user_id"]).to eq(user.id)
                space.reload
                new_role = space_manifest == :assemblies ? Decidim::AssemblyMember.find_by(decidim_assembly_id: space.id, decidim_user_id: user.id) : space.user_roles.find_by(decidim_user_id: user.id)
                expect(new_role).to be_present
                expect(new_role.role).to eq("collaborator") if new_role.respond_to?(:role)
              end
            end
          end
        end

        response "201", "Role created (general_admin)" do
          let(:body) do
            {
              data: {
                attributes: {
                  resource_type: "Decidim::Organization",
                  resource_id: organization.id,
                  user_id: user.id,
                  type: "general_admin"
                }
              }
            }
          end

          run_test!(example_name: :general_admin_ok) do |example|
            data = JSON.parse(example.body)["data"]
            expect(data["id"]).to be_present
            expect(data["attributes"]["type"]).to eq("general_admin")
            expect(data["attributes"]["resource_type"]).to eq("Decidim::Organization")
            expect(data["attributes"]["resource_id"]).to eq(organization.id)
            expect(data["attributes"]["user_id"]).to eq(user.id)
          end
        end

        response "422", "Validation error" do
          let(:body) do
            { data: { attributes: { resource_type: "Decidim::ParticipatoryProcess", resource_id: space.id, user_id: user.id, type: "invalid_type" } } }
          end

          run_test!(example_name: :invalid_type)
        end
      end
    end
  end
end
