---
sidebar_position: 7
title: Webhooks
description: Subscribe, verify HMAC signatures, and read event payloads.
---

# Webhooks

Outbound **HTTP POSTs** to URLs you configure — not part of the public REST CRUD API.

## Subscribe

1. Open **System admin → API clients**.
2. Edit a client → **Webhooks** tab.
3. Add URL + select **event subscriptions** (permission keys such as `proposal_creation.succeeded`).

Management is **admin UI only** today (no `POST /webhook_endpoints` in the integrator API).

## Verify signatures

Each delivery includes:

- `X-Webhook-Timestamp` — Unix seconds
- `X-Webhook-Signature` — `v1=` + HMAC-SHA256 hex of `"#{timestamp}.#{raw_body}"` using the webhook signing secret from admin

Reject stale timestamps on your side (clock skew window).

## Payload

JSON envelope:

```json
{
  "type": "proposal_creation.succeeded",
  "data": { }
}
```

Shape is JSON:API-oriented; see OpenAPI schema **WebhookDeliveryEnvelope** and the **Webhooks** tag event table in [ReDoc](/api).

## Retries

Non-2xx responses are retried by the platform job (see contributor [webhooks dev doc](/dev/add-endpoint/webhooks)).

## Event list

Authoritative catalog: [OpenAPI Webhooks tag](/api) (generated from `WebhookEventCatalog`).
