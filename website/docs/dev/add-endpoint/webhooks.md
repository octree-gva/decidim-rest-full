---
sidebar_position: 17
title: Webhooks
description: Add outbound webhook events to a feature gem.
---

# Webhooks (contributor)

Outbound HTTP callbacks. Integrators manage registrations via REST (`/webhook_registrations`) or System admin.

## Overview

- Register catalog + OpenAPI metadata with `Extension#webhook_event` (same pattern as routes / OpenAPI definitions).
- Wire Decidim `ActiveSupport::Notifications` with `Extension#webhooks(..., handler:)` — handler is required.
- Delivery: [`WebhookJob`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/decidim-restfull-core/app/jobs/decidim/rest_full/core/webhook_job.rb) → [`WebhookRegistration#send_webhook`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/decidim-restfull-core/app/models/decidim/rest_full/core/webhook_registration.rb) (HMAC headers).
- OpenAPI: per-event envelopes under **WebhookDeliveryEnvelope**; example payloads via `GET /webhook_events/{event_type}`.

## Checklist — new event

1. `ext.webhook_event(…)` in your engine — pass `example:` (callable), optional short `schema_key:`, and `payload_schema_ref:`.
2. `ext.webhooks(pattern, handler: …)` — map Decidim notification → job that uses your webhook serializer.
3. Implement a `*WebhookSerializer` with `find_example_resource` (used by `example_envelope`).
4. Locale label in `decidim_rest_full_<gem>.en.yml` under `api_client.permission`.
5. Specs: pass a real resource into the webhook serializer (not canned hashes).
6. Core oauth/system events still sync from `Core::Configuration`; proposals/meetings/spaces register in their engines.

## Examples

**Feature gem (proposals):**

```ruby
ext.webhook_event(
  "proposal_creation.succeeded",
  scope: :proposals,
  payload_schema_ref: :proposal,
  schema_key: :wh_proposal_creation,
  trigger: "Proposal lifecycle notification",
  example: ->(org) {
    Decidim::Api::RestFull::Proposals::ProposalWebhookSerializer.example_envelope(
      org, event_name: "proposal_creation.succeeded"
    )
  }
)
ext.webhooks(
  /decidim\.events\./,
  /decidim\.proposals\./,
  handler: Decidim::RestFull::Core::WebhookDispatcher.instance.method(:handle_proposals)
)
```

**Meetings / spaces:** see their engines for `webhook_event` + handler wiring.

## Payload & security

Envelope: `type`, `data`. Headers: `X-Webhook-Signature` (`v1=` + HMAC-SHA256 hex over `timestamp + "." + body`), `X-Webhook-Timestamp`.

OpenAPI schema keys use a short `wh_*` prefix (override with `schema_key:`).

## Fire sample payloads

Integrators can POST a typed sample to a local URL:

```bash
bundle exec rails decidim_rest_full:fire_webhook URL=https://… EVENT=decidim.step_activated
```

See [integrator webhooks](/integrator/webhooks#fire-a-sample-delivery-local--staging).

## See also

- [Integrator webhooks](/integrator/webhooks)
- OpenAPI **Webhooks** tag
