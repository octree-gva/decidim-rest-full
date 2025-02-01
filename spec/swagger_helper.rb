# frozen_string_literal: true

require "spec_helper"
require "rswag/specs"
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s
  config.after do |example|
    next unless example.metadata[:type] == :request

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
          [Get a token](#{Decidim::RestFull.docs_url}/category/authentication) from our `/oauth/token` routes,
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
        Api::Definitions::Tags::OAUTH,
        Api::Definitions::Tags::SYSTEM,
        Api::Definitions::Tags::PUBLIC,
        Api::Definitions::Tags::BLOG,
        Api::Definitions::Tags::PROPOSAL
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
              [Learn more here](#{Decidim::RestFull.docs_url}/user_documentation/auth/client-credential-flow)
            README
          },
          resourceOwnerFlowBearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: <<~README
              Authorization via resource owner flow.
              Use this for user-based authentication
              [Learn more here](#{Decidim::RestFull.docs_url}/user_documentation/auth/user-credentials-flow)
            README
          }
        },
        schemas: {
          # Reusable properties
          api_error: Api::Definitions::ERROR,
          translated_prop: Api::Definitions::TRANSLATED_PROP,
          component_type: Api::Definitions::COMPONENT_TYPE,
          component_manifest: Api::Definitions::COMPONENT_MANIFEST,
          space_manifest: Api::Definitions::SPACE_MANIFEST,
          space_type: Api::Definitions::SPACE_TYPE,
          locales: Api::Definitions::LOCALES_PARAM,
          locale: Api::Definitions::LOCALE_PARAM,
          creation_date: Api::Definitions::CREATION_DATE,
          edition_date: Api::Definitions::EDITION_DATE,

          # System
          organization: Api::Definitions::ORGANIZATION,
          user: Api::Definitions::USER,
          organizations_response: Api::Definitions.array_response("organization", "List of organizations"),
          users_response: Api::Definitions.array_response("user", "List of users"),
          user_extended_data_response: Api::Definitions.item_response("user_extended_data", "Extended data response for a given path"),
          user_extended_data: Api::Definitions::USER_EXTENDED_DATA,

          # Public
          space: Api::Definitions::SPACE,
          proposal_component: Api::Definitions::PROPOSAL_COMPONENT,
          component: Api::Definitions::COMPONENT,
          component_response: Api::Definitions.item_response("component", "Component Detail"),
          components_response: Api::Definitions.array_response("component", "Components List"),
          proposal_component_response: Api::Definitions.item_response("proposal_component", "Proposal Component Detail"),
          proposal_components_response: Api::Definitions.array_response("proposal_component", "Proposal Components List"),
          spaces_response: Api::Definitions.array_response("space", "Participatory Spaces List"),
          space_response: Api::Definitions.item_response("space", "Participatory Space Detail"),

          # Blogs
          blog: Api::Definitions::BLOG,
          blogs_response: Api::Definitions.array_response("blog", "Blog Post List"),
          blog_response: Api::Definitions.item_response("blog", "Blog Post Detail"),

          # Proposal
          proposal: Api::Definitions::PROPOSAL,
          proposals_response: Api::Definitions.array_response("proposal", "Proposals List"),
          proposal_response: Api::Definitions.item_response("proposal", "Proposal Detail"),
          draft_proposal: Api::Definitions::DRAFT_PROPOSAL,
          draft_proposal_response: Api::Definitions.item_response("draft_proposal", "Draft Proposal Detail"),

          # OAuth methods
          introspect_data: Api::Definitions::INTROSPECT_DATA,
          introspect_response: {
            description: "Details about the token beeing used",
            "$ref" => "#/components/schemas/introspect_data"
          },
          magic_link: Api::Definitions::MAGIC_LINK,
          magic_link_response: Api::Definitions.item_response("magic_link", "Magick Link Response"),
          magic_link_redirect: Api::Definitions::MAGIC_LINK_REDIRECT,
          magic_link_redirect_response: Api::Definitions.item_response("magic_link_redirect", "Magick Link Redirect"),

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
