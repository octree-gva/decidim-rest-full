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
| 0.28    | yes       |
| 0.29    | yes       |
| 0.27 and older | no |

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
| `DOCS_URL` | Base URL for generated docs | `https://octree-gva.github.io/decidim-rest-full` |

For capacity planning (Puma, Redis, Sidekiq, k6, client patterns), see [Production mode](/production-mode).
