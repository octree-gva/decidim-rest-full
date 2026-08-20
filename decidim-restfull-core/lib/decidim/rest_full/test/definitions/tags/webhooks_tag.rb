# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        WEBHOOKS = {
          name: "Webhooks",
          description: <<~TXT.strip
            **Outbound HTTP callbacks** plus REST management of registrations.

            ### Manage registrations
            - `GET|POST /webhook_registrations` — list / create (signing secret returned **only on create**)
            - `GET|PUT|DELETE /webhook_registrations/{id}` — show / update / destroy (scoped to the API client)
            - `GET /webhook_events/{event_type}` — canned example payload for typed clients

            Subscribe via this API or in **System admin → API clients → Webhooks**.

            Verify deliveries with `X-Webhook-Signature` (`v1=` + HMAC-SHA256 hex of `timestamp + "." + raw body`) and `X-Webhook-Timestamp`.

            Payload envelope: schema **WebhookDeliveryEnvelope** (discriminated on `type`).

            ### Event catalog

            #{Decidim::RestFull::Core::WebhookEventCatalog.markdown_table}
          TXT
        }.freeze
      end
    end
  end
end
