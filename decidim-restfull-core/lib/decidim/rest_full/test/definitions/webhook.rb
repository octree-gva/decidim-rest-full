# frozen_string_literal: true

# Placeholder envelope; replaced by finalize_webhook_delivery_schemas! after feature schemas load.
Decidim::RestFull::Core::DefinitionRegistry.register_object(:webhook_delivery_envelope) do
  {
    title: "Webhook delivery envelope",
    type: :object,
    description: "JSON body POSTed to integrator URLs when a subscribed event fires.",
    properties: {
      type: {
        type: :string,
        description: "Event name (matches permission / subscription key, e.g. `proposal_creation.succeeded`)"
      },
      data: {
        type: :object,
        description: "JSON:API-shaped resource payload for the event"
      }
    },
    required: [:type, :data],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:webhook_registration_attributes) do
  {
    title: "Webhook Registration Attributes",
    type: :object,
    properties: {
      url: { type: :string, format: :uri, description: "HTTPS callback URL" },
      subscriptions: {
        type: :array,
        items: { type: :string },
        description: "Event keys this registration receives"
      },
      signing_secret: {
        type: :string,
        description: "HMAC signing secret (returned only on create)"
      },
      created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
      updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
    },
    required: [:url, :subscriptions, :created_at, :updated_at],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:webhook_registration_create_attributes) do
  {
    title: "Webhook Registration Create Attributes",
    type: :object,
    properties: {
      url: { type: :string, format: :uri, description: "HTTPS callback URL" },
      subscriptions: {
        type: :array,
        items: { type: :string },
        minItems: 1,
        description: "Event keys to subscribe (must be granted as event permissions on the API client)"
      }
    },
    required: [:url, :subscriptions],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:webhook_registration_create_body) do
  {
    title: "Webhook Registration Create Body",
    type: :object,
    properties: {
      data: {
        type: :object,
        properties: {
          attributes: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_create_attributes) }
        },
        required: [:attributes]
      }
    },
    required: [:data],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:webhook_registration) do
  {
    type: :object,
    title: "Webhook Registration",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["webhook_registration"] },
      attributes: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:webhook_registration_attributes) }
    },
    required: [:id, :type, :attributes],
    additionalProperties: false
  }.freeze
end
