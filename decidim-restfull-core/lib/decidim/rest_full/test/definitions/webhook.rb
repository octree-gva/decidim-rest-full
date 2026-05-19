# frozen_string_literal: true

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
