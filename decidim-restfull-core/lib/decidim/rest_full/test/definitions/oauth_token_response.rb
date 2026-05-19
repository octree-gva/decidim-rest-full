# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:oauth_token_response) do
  {
    type: :object,
    title: "OAuth token response",
    description: "Doorkeeper access token payload (RFC 6749).",
    properties: {
      access_token: { type: :string, description: "Bearer token value" },
      token_type: { type: :string, enum: ["Bearer"] },
      expires_in: { type: :integer, description: "Lifetime in seconds" },
      scope: { type: :string, description: "Granted scopes (space-separated)" },
      created_at: { type: :integer, description: "Unix timestamp when the token was issued" }
    },
    required: %w(access_token token_type expires_in scope created_at),
    additionalProperties: false
  }.freeze
end
