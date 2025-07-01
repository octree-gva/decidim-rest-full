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
                A RestFull API for Decidim, to be able to CRUD resources from Decidim.

                ## Authentication
                [Get a token](#{Decidim::RestFull.config.docs_url}/category/authentication) from our `/oauth/token` routes,
                following OAuth specs on Credential Flows or Resource Owner Password Credentials Flow.

                ### Permissions
                A permission system is attached to the created OAuth application, that is designed in two levels:

                - **scope**: a broad permission to access a collection of endpoints
                - **abilities**: a fine grained permission system that allow actions.

                The scopes and abilities are manageable in your System Admin Panel.

                ### Multi-tenant
                Decidim is multi-tenant, and this API supports it.
                - The **`system` scope** endpoints are available in any tenant
                - The tenant `host` attribute will be used to guess which tenant you are requesting.
                  For example, given a tenant `example.org` and `foobar.org`, the endpoint
                  * `example.org/oauth/token` will ask a token for the example.org organization
                  * `foobar.org/oauth/token` for foobar.org.
              README
            },
            servers: [
              {
                url: "https://{defaultHost}/api/rest_full/v#{Decidim::RestFull.major_minor_version}",
                variables: {
                  defaultHost: {
                    default: "www.example.com"
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
              Definitions::Tags::BLOG,
              Definitions::Tags::PROPOSAL,
              Definitions::Tags::METRICS
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
              schemas: Decidim::RestFull::DefinitionRegistry.as_json
            }
          }
        }
      end
    end
  end
end
