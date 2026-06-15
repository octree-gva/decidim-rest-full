---
sidebar_position: 17
title: Webhooks
description: Add outbound webhook events to a feature gem.
---

# Webhooks (contributor)

Outbound HTTP callbacks — not REST routes.

## Overview

- Register listeners with `Extension#webhooks` in your engine.
- Delivery: [`WebhookJob`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/decidim-restfull-core/app/jobs/decidim/rest_full/core/webhook_job.rb) → [`WebhookRegistration#send_webhook`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/decidim-restfull-core/app/models/decidim/rest_full/core/webhook_registration.rb) (HMAC headers).

## Checklist — new event

1. Add event string to `events_for_<scope>` in `Core::Configuration` (or `WebhookEventCatalog.register`).
2. Ensure permission appears under `available_permissions` for that scope.
3. `ext.webhooks(/pattern/, …)` in engine — default proposals pipeline or custom handler.
4. Serialize payload in job/handler (JSON:API-shaped `data`).
5. `WebhookEventCatalog.register(…)` for OpenAPI table + docs.
6. Locale label in `decidim_rest_full_<gem>.en.yml` under `api_client` permissions.

## Examples

**Proposals (regex on Decidim notifications):**

```ruby
ext.webhooks(/decidim\.events\./, /decidim\.proposals\./)
```

**Meetings (custom handler):** see `decidim-restfull-meetings` `UpcomingMeetingWebhookHandler`.

## Payload & security

Envelope: `type`, `data`. Headers: `X-Webhook-Signature`, `X-Webhook-Timestamp` (HMAC-SHA256 over `timestamp + "." + body`).

## See also

- [Integrator webhooks](/integrator/webhooks)
- OpenAPI **Webhooks** tag
