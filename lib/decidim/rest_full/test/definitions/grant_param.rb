# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:client_credential) do
  {
    type: :object,
    title: "Client Credential",
    properties: {
      grant_type: { type: :string, enum: ["client_credentials"], description: "Client Credential Flow, for **machine-to-machine**" },
      client_id: { type: :string, description: "OAuth application Client Id" },
      client_secret: { type: :string, description: "OAuth application Client Secret" },
      scope: { type: :string, enum: Doorkeeper.configuration.scopes.to_a.map(&:to_s), description: "Requested scopes" }
    },
    required: %w(grant_type client_id client_secret scope)
  }
end
Decidim::RestFull::DefinitionRegistry.register_object(:password_grant_login) do
  {
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
end

Decidim::RestFull::DefinitionRegistry.register_object(:password_grant_impersonate) do
  {
    type: :object,
    title: "Impersonation",
    properties: {
      grant_type: { type: :string, enum: ["password"], description: "Resource Owner Password Credentials (ROPC) Flow, for **user impersonation**" },
      auth_type: { type: :string, enum: ["impersonate"], description: "Type of ROPC" },
      username: { type: :string, description: "User nickname, unique and at least 6 alphanumeric chars." },
      id: { type: :string, description: "User id, will find over id and ignore username. Fails if register_on_missing=true." },
      meta: {
        type: :object,
        title: "User impersonation settings",
        description: "Impersonation Settings",
        properties: {
          register_on_missing: { type: :boolean, description: "Register the user if it does not exists. Default: false" },
          accept_tos_on_register: { type: :boolean, description: "Accept the TOS on registration, used only if register_on_missing=true. Default: false" },
          skip_confirmation_on_register: { type: :boolean, description: "Skip email confirmation on creation, used only if register_on_missing=true. Default: false" },
          email: { type: :string, description: "User email to use on registration. used only if register_on_missing=true. Default to <username>@example.org" },
          name: { type: :string, description: "User name. Used only if register_on_missing=true. Default to username" }
        },
        additionalProperties: false
      },
      client_id: { type: :string, description: "OAuth application Client Id" },
      client_secret: { type: :string, description: "OAuth application Client Secret" },
      scope: { type: :string, enum: Doorkeeper.configuration.scopes.to_a.reject { |scope| scope == "system" }, description: "Request scopes" }
    },
    additionalProperties: false,
    required: %w(grant_type client_id client_secret scope auth_type)
  }.freeze
end

Decidim::RestFull::DefinitionRegistry.register_object(:oauth_grant_param) do
  {
    oneOf: [
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:client_credential) },
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:password_grant_impersonate) },
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:password_grant_login) }
    ]
  }
end

Decidim::RestFull::DefinitionRegistry.register_object(:password_grant_param) do
  {
    oneOf: [
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:password_grant_impersonate) },
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:password_grant_login) }
    ]
  }
end
