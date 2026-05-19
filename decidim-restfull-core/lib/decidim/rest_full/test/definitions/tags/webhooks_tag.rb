# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        WEBHOOKS = {
          name: "Webhooks",
          description: <<~TXT.strip
            **Outbound HTTP callbacks** (not REST paths). Subscribe in **System admin → API clients → Webhooks**.

            Verify deliveries with `X-Webhook-Signature` (HMAC-SHA256 over `timestamp + "." + raw body`) and `X-Webhook-Timestamp`.

            Payload envelope: see schema **WebhookDeliveryEnvelope**.

            ### Event catalog

            #{Decidim::RestFull::Core::WebhookEventCatalog.markdown_table}
          TXT
        }.freeze
      end
    end
  end
end
