---
sidebar_position: 7
title: Webhooks
description: Subscribe, verify HMAC signatures, and read event payloads.
---

# Webhooks

Outbound **HTTP POSTs** to URLs you configure. Manage registrations via the REST API or System admin.

## Subscribe

### REST API (recommended for automation)

Requires OAuth scope `webhooks` and permissions `webhooks.read` / `webhooks.write` / `webhooks.destroy`.

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `/webhook_registrations` | List registrations for the current API client |
| `POST` | `/webhook_registrations` | Create; returns `signing_secret` **once** |
| `GET` | `/webhook_registrations/{id}` | Show (no secret) |
| `PUT` | `/webhook_registrations/{id}` | Update URL / subscriptions |
| `DELETE` | `/webhook_registrations/{id}` | Destroy |
| `GET` | `/webhook_events/{event_type}` | Canned example payload for typed clients |

Subscriptions must already be granted as **event permissions** on the API client (e.g. `proposal_creation.succeeded`).

### System admin

1. Open **System admin → API clients**.
2. Edit a client → **Webhooks** tab.
3. Add URL + select **event subscriptions**.

## Verify signatures

Each delivery includes:

- `X-Webhook-Timestamp` — Unix seconds
- `X-Webhook-Signature` — `v1=` + HMAC-SHA256 hex of `"#{timestamp}.#{raw_body}"` using the webhook signing secret

Reject stale timestamps on your side (clock skew window).

## Payload

JSON envelope:

```json
{
  "type": "proposal_creation.succeeded",
  "data": { }
}
```

Shape is JSON:API-oriented; see OpenAPI schema **WebhookDeliveryEnvelope** (discriminated on `type`) and `GET /webhook_events/{event_type}` for examples. Full event table: [OpenAPI Webhooks tag](/api).

## Retries

Non-2xx responses are retried by the platform job (see contributor [webhooks dev doc](/dev/add-endpoint/webhooks)).

## Fire a sample delivery (local / staging)

Who reads this: integrators wiring a receiver and wanting a real signed POST without waiting for a Decidim action.

```bash
bundle exec rails decidim_rest_full:fire_webhook \
  URL=https://webhook.site/your-id \
  EVENT=decidim.step_activated
```

| ENV | Required | Default | Notes |
|-----|----------|---------|-------|
| `URL` | yes | — | `http` or `https` callback |
| `EVENT` | yes | — | Catalog name (e.g. `proposal_creation.succeeded`) or alias (`decidim.step_activated`, `step_activated`, `proposal_published`). Use `EVENT=list` to print known events |
| `HOST` | no | first org | Organization host used to build a typed sample from real tenant data |
| `ORGANIZATION_ID` | no | — | Alternative to `HOST` |
| `SECRET` | no | random 64-hex | HMAC signing secret (printed in the JSON result when generated) |
| `DRY_RUN` | no | unset | Set to `1` to print the payload JSON without POSTing |

The payload is type-correct for the OpenAPI **WebhookDeliveryEnvelope** (same builders as `GET /webhook_events/{event_type}`). Headers match production (`X-Webhook-Signature` / `X-Webhook-Timestamp`).

## Event list

Authoritative catalog: [OpenAPI Webhooks tag](/api) (generated from `WebhookEventCatalog`).
