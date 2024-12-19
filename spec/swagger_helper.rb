# frozen_string_literal: true

# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s
  config.after do |example|
    content = example.metadata[:response][:content] || {}
    example_name = example.metadata[:example_name]
    if example_name
      response && response.body ? response.body : "{}"
      json_data = begin
        JSON.parse(response.body, symbolize_names: true)
      rescue StandardError
        {}
      end
      example_spec = {
        "application/json" => {
          examples: {
            example_name.to_sym => {
              value: json_data
            }
          }
        }
      }
      example.metadata[:response][:content] = content.deep_merge(example_spec)
    end
  end
  config.openapi_specs = {
    "v1/swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "API V1",
        version: "v#{Decidim::RestFull.major_minor_version}",
        description: <<~README
          A RestFull API for Decidim, to be able to CRUD resources from Decidim.

          ## Authentication
          [Get a token](#{Decidim::RestFull.docs_url}/category/authentication) from our `/oauth/token` routes,#{" "}
          following OAuth specs on Credential Flows or Resource Owner Password Credentials Flow.

          ### Permissions
          A permission system is attached to the created OAuth application, that is designed in two levels:#{" "}

          - **scope**: a broad permission to access a collection of endpoints
          - **abilities**: a fine grained permission system that allow actions.#{" "}

          The scopes and abilities are manageable in your System Admin Panel.

          ### Multi-tenant
          Decidim is multi-tenant, and this API supports it.
          - The **`system` scope** endpoints are available in any tenant
          - The tenant `host` attribute will be used to guess which tenant you are requesting.#{" "}
            For example, given a tenant `example.org` and `foobar.org`, the endpoint
            * `example.org/oauth/token` will ask a token for the example.org organization
            * `foobar.org/oauth/token` for foobar.org.
        README
      },
      security: [
        {
          resourceOwnerFlowBearer: []

        }
      ],
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
        {
          name: "OAuth",
          description: "Use OAuth to get tokens and interact with the API. You can use machine-to-machine tokens, or user token directly with the API." \
                       "\n* **Machine-to-machine**: Client Credential Flow" \
                       "\n* **User**: Resource Owner Password Credential Flow, with **impersonation** or **login**",

          externalDocs: {
            description: "How to authenticate",
            url: "#{Decidim::RestFull.docs_url}/category/authentication"
          }
        }
      ],
      components: {
        securitySchemes: {
          credentialFlowBearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: "Authorization via service-to-service credentials flow. Use this for machine clients. [Learn more here](#{Decidim::RestFull.docs_url}/user_documentation/auth/client-credential-flow)"
          },
          resourceOwnerFlowBearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: "Authorization via resource owner flow. Use this for user-based authentication [Learn more here](#{Decidim::RestFull.docs_url}/user_documentation/auth/user-credentials-flow)"

          }
        },
        schemas: {
          api_error: Api::Definitions::ERROR,
          translated_prop: Api::Definitions::TRANSLATED_PROP,
          organizations_response: {
            type: :object,
            properties: {
              data: {
                type: :array,
                items: { "$ref" => "#/components/schemas/organization" }
              }
            },
            required: [:data]
          },
          organization: Api::Definitions::ORGANIZATION,
          users_response: {
            type: :object,
            properties: {
              data: {
                type: :array,
                items: { "$ref" => "#/components/schemas/user" }
              }

            },
            required: [:data]
          },
          user: Api::Definitions::USER,
          space: Api::Definitions::SPACE,
          component: Api::Definitions::COMPONENT,
          blog: Api::Definitions::BLOG,
          blogs_response: {
            type: :object,
            description: "Details of a given Blog Post",
            properties: {
              data: {
                type: :array,
                items: { "$ref" => "#/components/schemas/blog" }
              }
            },
            required: [:data]
          },
          blog_response: {
            type: :object,
            description: "Details of a given Blog Post",
            properties: {
              data: { "$ref" => "#/components/schemas/blog" }
            },
            required: [:data]

          },
          component_response: {
            type: :object,
            description: "Details of a given component",
            properties: {
              data: { "$ref" => "#/components/schemas/component" }
            },
            required: [:data]
          },
          components_response: {
            type: :object,
            description: "List of components",
            properties: {
              data: {
                type: :array,
                items: { "$ref" => "#/components/schemas/component" }
              }
            },
            required: [:data]
          },
          spaces_response: {
            description: "List of spaces",
            type: :object,
            properties: {
              data: {
                type: :array,
                items: { "$ref" => "#/components/schemas/space" }
              }
            },
            required: [:data]
          },
          space_response: {
            description: "Definition of one specific space",
            type: :object,
            properties: {
              data: { "$ref" => "#/components/schemas/space" }
            },
            required: [:data]
          },
          introspect_data: Api::Definitions::INTROSPECT_DATA,
          introspect_response: {
            description: "Details about the token beeing used",
            "$ref" => "#/components/schemas/introspect_data"
          },
          oauth_grant_param: {
            oneOf: [
              Api::Definitions::CLIENT_CREDENTIAL_GRANT,
              Api::Definitions::PASSWORD_GRANT_IMPERSONATE,
              Api::Definitions::PASSWORD_GRANT_LOGIN
            ]
          },
          password_grant_param: {
            oneOf: [
              Api::Definitions::PASSWORD_GRANT_IMPERSONATE,
              Api::Definitions::PASSWORD_GRANT_LOGIN
            ]
          }
        }
      }
    }
  }
end
