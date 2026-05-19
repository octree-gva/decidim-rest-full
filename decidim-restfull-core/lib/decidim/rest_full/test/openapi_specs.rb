# frozen_string_literal: true

module Decidim
  module RestFull
    module Test
      def self.openapi_specs
        {
          "v1/swagger.json" => {
            openapi: "3.0.1",
            info: {
              title: "API V1",
              version: "v#{Decidim::RestFull.major_minor_version}",
              description: <<~README
                A RestFull API for Decidim, to be able to CRUD resources from Decidim.#{"  "}
                _current version: #{Decidim::RestFull.version}_

                ## Authentication
                [Get a token](#{Decidim::RestFull.config.docs_url}/category/authentication) from our `/oauth/token` routes,
                following OAuth specs on Credential Flows or Resource Owner Password Credentials Flow.

                ### Permissions
                A permission system is attached to the created OAuth application, that is designed in two levels:

                - **scope**: a broad permission to access a collection of endpoints
                - **abilities**: a fine grained permission system that allow actions.

                The scopes and abilities are manageable in your System Admin Panel.

                ### Multi-tenant **Organizations**
                One deployment hosts many **Organizations** (tenants by **`host`**).
                - The **`system` scope** endpoints apply in the context of the resolved organization
                - The request **`host`** selects which **Organization** you target.
                  For example, `example.org/oauth/token` and `foobar.org/oauth/token` obtain tokens for those organizations' OAuth applications.

                ### Integrators
                Start with the [Integrator quickstart](#{Decidim::RestFull.config.docs_url}/integrator/quickstart) (host → API client → token → first API call).

                TypeScript client: [#{Decidim::RestFull.config.docs_url}/integrator/typescript-sdk](#{Decidim::RestFull.config.docs_url}/integrator/typescript-sdk) (`@octree/decidim-sdk`).

                Outbound **webhook** events are listed under the **Webhooks** tag (subscribe in System admin).
              README
            },
            servers: [
              {
                url: "https://{defaultHost}/api/rest_full/v#{Decidim::RestFull.major_minor_version}",
                variables: {
                  defaultHost: {
                    default: "www.example.org"
                  }
                }
              }
            ],
            tags: [
              Definitions::Tags::OAUTH,
              Definitions::Tags::ORGANIZATIONS,
              Definitions::Tags::ORGANIZATION_EXTENDED_DATA,
              Definitions::Tags::SPACE,
              Definitions::Tags::COMPONENT,
              Definitions::Tags::USER,
              *Decidim::RestFull::Test::OpenApiTagRegistry.tag_definitions,
              Definitions::Tags::JOBS,
              Definitions::Tags::ROLES,
              Definitions::Tags::WEBHOOKS
            ],
            components: {
              securitySchemes: {
                credentialFlowBearer: {
                  type: :http,
                  scheme: :bearer,
                  bearerFormat: :JWT,
                  description: <<~README
                    Authorization via service-to-service credentials flow.
                    Use this for machine clients.
                    [Learn more here](#{Decidim::RestFull.config.docs_url}/user_documentation/auth/client-credential-flow)
                  README
                },
                resourceOwnerFlowBearer: {
                  type: :http,
                  scheme: :bearer,
                  bearerFormat: :JWT,
                  description: <<~README
                    Authorization via resource owner flow.
                    Use this for user-based authentication
                    [Learn more here](#{Decidim::RestFull.config.docs_url}/user_documentation/auth/user-credentials-flow)
                  README
                }
              },
              schemas: Decidim::RestFull::Core::DefinitionRegistry.as_json
            }
          }
        }
      end
    end
  end
end
