# frozen_string_literal: true

module Api
  module Definitions
    CLIENT_CREDENTIAL_GRANT = {
      type: :object,
      title: "Client Credential",
      properties: {
        grant_type: { type: :string, enum: ["client_credentials"], description: "Client Credential Flow, for **machine-to-machine**" },
        client_id: { type: :string, description: "OAuth application Client Id" },
        client_secret: { type: :string, description: "OAuth application Client Secret" },
        scope: { type: :string, enum: Doorkeeper.configuration.scopes.to_a, description: "Requested scopes" }
      },
      required: %w(grant_type client_id client_secret scope)
    }.freeze
  end
end
