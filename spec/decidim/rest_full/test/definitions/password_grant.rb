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
        extra: {
          type: :object,
          title: "User extra data",
          description: "Additional properties for the user (private)",
          properties: {
            email: { type: :string, description: "User email. Default to <username>@example.org" }
          }
        },
        meta: {
          type: :object,
          title: "User impersonation settings",
          description: "Impersonation Settings",
          properties: {
            register_on_missing: { type: :boolean, description: "Register the user if it does not exists. Default: false" },
            accept_tos_on_register: { type: :boolean, description: "Accept the TOS on registration, valid only if register_on_missing=true. Default: false" },
            skip_confirmation_on_register: { type: :boolean, description: "Skip email confirmation on creation, valid only if register_on_missing=true. Default: false" }
          }
        },
        client_id: { type: :string, description: "OAuth application Client Id" },
        client_secret: { type: :string, description: "OAuth application Client Secret" },
        scope: { type: :string, enum: Doorkeeper.configuration.scopes.to_a.reject { |scope| scope == "system" }, description: "Request scopes" }
      },
      required: %w(grant_type client_id client_secret scope username auth_type)
    }.freeze
  end
end
