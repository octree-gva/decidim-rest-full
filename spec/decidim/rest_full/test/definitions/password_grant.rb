# frozen_string_literal: true

# spec/support/api_schemas/organization_schema.rb
module Api
  module Definitions
    PASSWORD_GRANT_LOGIN = {
      type: :object,
      title: "Login",
      properties: {
        grant_type: { type: :string, enum: ["password"], description: "Resource Owner Password Credentials (ROPC) Flow, for **user login**" },
        auth_type: { type: :string, enum: ["login"], description: "Type of ROPC" },
        username: { type: :string, description: "User nickname" },
        password: { type: :string, description: "User password" },
        client_id: { type: :string, description: "OAuth application Client Id" },
        client_secret: { type: :string, description: "OAuth application Client Secret" },
        scope: { type: :string, enum: Doorkeeper.configuration.scopes.to_a.reject { |scope| scope == "system" }, description: "Request scopes" }
      },
      required: %w(grant_type client_id client_secret scope username password auth_type)
    }.freeze

    PASSWORD_GRANT_IMPERSONATE = {
      type: :object,
      title: "Impersonation",
      properties: {
        grant_type: { type: :string, enum: ["password"], description: "Resource Owner Password Credentials (ROPC) Flow, for **user impersonation**" },
        auth_type: { type: :string, enum: ["impersonate"], description: "Type of ROPC" },
        username: { type: :string, description: "User nickname" },
        client_id: { type: :string, description: "OAuth application Client Id" },
        client_secret: { type: :string, description: "OAuth application Client Secret" },
        scope: { type: :string, enum: Doorkeeper.configuration.scopes.to_a.reject { |scope| scope == "system" }, description: "Request scopes" }
      },
      required: %w(grant_type client_id client_secret scope username auth_type)
    }.freeze
  end
end
