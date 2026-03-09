# frozen_string_literal: true

module Decidim
  module RestFull
    module OpenAPI
      # Builds the base OpenAPI 3 hash (info, servers, tags, components) without running RSpec.
      # Used by the decidim-rest_full-openapi binstub. Paths come from Rswag request specs.
      class Export
        def self.build(host:, locales: nil, docs_url: nil)
          new(host:, locales:, docs_url:).to_h
        end

        def initialize(host:, locales: nil, docs_url: nil)
          @host = host.to_s.sub(%r{/$}, "")
          @locales = locales
          @docs_url = docs_url || Decidim::RestFull.config.docs_url
        end

        def to_h
          {
            openapi: "3.0.1",
            info:,
            servers:,
            tags:,
            components: {
              securitySchemes: security_schemes,
              schemas: Decidim::RestFull::DefinitionRegistry.as_json
            }
          }.deep_stringify_keys
        end

        private

        def info
          {
            title: "API V1",
            version: "v#{Decidim::RestFull.major_minor_version}",
            description:
          }.deep_stringify_keys
        end

        def description
          <<~README
            A RestFull API for Decidim.
            _current version: #{Decidim::RestFull.version}_

            ## Authentication
            [Get a token](#{@docs_url}/category/authentication) from our `/oauth/token` routes,
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
          README
        end

        def servers
          [
            { url: "#{@host}/api/rest_full/v#{Decidim::RestFull.major_minor_version}" }
          ].map(&:deep_stringify_keys)
        end

        def tags
          tags_module = Decidim::RestFull::Definitions::Tags
          [:API, :OAUTH, :ORGANIZATIONS, :ORGANIZATION_EXTENDED_DATA, :SPACE, :COMPONENT, :USER, :BLOG, :PROPOSAL]
            .filter_map { |c| tags_module.const_get(c) if tags_module.const_defined?(c) }
            .map(&:deep_stringify_keys)
        end

        def security_schemes
          {
            credentialFlowBearer: {
              type: :http,
              scheme: :bearer,
              bearerFormat: :JWT,
              description: "Authorization via service-to-service credentials flow. [Learn more](#{@docs_url}/user_documentation/auth/client-credential-flow)"
            },
            resourceOwnerFlowBearer: {
              type: :http,
              scheme: :bearer,
              bearerFormat: :JWT,
              description: "Authorization via resource owner flow. [Learn more](#{@docs_url}/user_documentation/auth/user-credentials-flow)"
            }
          }.deep_stringify_keys
        end
      end
    end
  end
end
