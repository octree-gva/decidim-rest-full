---
sidebar_position: 2
slug: /install
title: Installation
description: How to install the module
---

Install the gem on your **host application** so Decidim keeps owning domain logic; this module only adds the HTTP API surface described in the [overview](/).

## Decidim compatibility

| Decidim | Supported |
|---------|-----------|
| 0.32    | yes (first-class; OpenAPI contract) |
| 0.31    | no |
| 0.30    | no |
| 0.29    | yes (CI via Appraisals) |
| 0.28 and older | no |

## Install

Add the metagem to your host app `Gemfile`:

```ruby
gem "decidim-restfull", "~> 0.3"
```

Then:

```bash
bundle install
bundle add deface
bundle exec rails decidim_rest_full:install:migrations
bundle exec rails db:migrate
bundle exec rails deface:precompile
```

## Host app extensions

Tenant-specific routes (chatbot bridges, legacy paths, one-deployment APIs) can register on the RestFull mount from the host app via **`Extension.register`** — no feature gem required. See [Host app extensions](/dev/host-app-extension).

## Environment variables

| Name | Description | Default |
|------|-------------|---------|
| `DECIDIM_REST_QUEUE_NAME` | Active Job queue name | `default` |
| `DECIDIM_REST_LOADBALANCER_IPS` | CSV of load balancer IPs for safe `host` handling. See [Safe host update](/dev/update-hosts). | `127.0.0.1, ::1` |
| `DECIDIM_REST_MAX_ASYNC_API_JOB_PAYLOAD_BYTES` | Cap async job JSON payload size | unset (no limit) |
| `DECIDIM_REST_MAX_EXTENDED_DATA_PAYLOAD_BYTES` | Cap sync `extended_data` stored JSON size; falls back to the async cap when unset | unset (no limit) |
| `DOCS_URL` | Sets `Decidim::RestFull.config.docs_url` (links baked into OpenAPI) | Default from `configuration.rb` when unset |

For capacity planning (Puma, Redis, Sidekiq, k6, client patterns), see [Production mode](/production-mode).
