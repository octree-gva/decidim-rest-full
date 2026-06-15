---
title: Recipe
sidebar_position: 0
description: RestFull extension guide for Decidim gem authors — start here when adding HTTP endpoints.
---

## Overview

**For:** maintainers of a `decidim-restfull-*` gem (or an external RestFull extension gem) adding HTTP endpoints.

**Not for:** calling the API from a client app — use [Operating the API](/docs/user_documentation/) and [ReDoc](/api/) instead.

Follow this page in order. Open [topic pages](./routing.md) only when you need a single concern (async, RSwag, serializers, …).

## Choose your shape

| Shape | When | Template |
|-------|------|----------|
| **Serializer-only** | Component appears in search/show JSON; no new HTTP routes | [`decidim-restfull-surveys`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/decidim-restfull-surveys/lib/decidim/rest_full/surveys/engine.rb) |
| **Read-only HTTP** | `GET` index/show only | `Decidim::RestFull::Routing.read_resources` — see [Routing](./routing.md) |
| **Async CRUD** | Mutations return 202 + job poll | `Decidim::RestFull::Routing.async_resources` + `ext.api_job` — see [Async](./async.md) |
| **Host-app one-off** | Tenant-specific API in the host Decidim app | [Host app extensions](../host-app-extension.md) + [Boot and extension](./boot-and-extension.md) |

## External gem checklist

1. **Gemspec** — depend on `decidim-restfull-core` and the matching `decidim-<feature>` gem.
2. **`ENGINE_ROOT`** — set in `lib/decidim-restfull-<feature>.rb` (see [RestFull engines](./restfull-engines.md)).
3. **Rails engine** — `lib/decidim/rest_full/<feature>/engine.rb` with initializer **`before: "rest_full.draw_routes"`** (and **`before: "rest_full.scopes"`** as a safety belt).
4. **`Extension.register`** in that initializer:
   - `ext.oauth_scopes` — only scopes **not** already in core (`:meetings`, `:debates`, … are built-in)
   - `ext.permissions`
   - `ext.routes` — use [Routing DSL](./routing.md)
   - `ext.api_job` for async mutations
   - `ext.rswag_specs` + `ext.open_api_definitions`
5. **Controller** under `app/controllers/decidim/api/rest_full/` — see [Controllers](./controllers.md).
6. **Request spec** — see [RSwag](./rswag.md).
7. **Verify** (Docker):
   ```bash
   docker compose exec rest_full bash -lc 'cd /home/module && bundle exec rails routes -g rest_full | head'
   docker compose exec rest_full bash -lc 'cd /home/module && RAILS_ENV=test bundle exec rspec <your-spec-path>'
   ```

## Monorepo-only extras

When adding a gem inside the `decidim-restfull/` monorepo, also:

- Register the gem in `decidim-restfull/decidim-restfull.gemspec`
- Add the gem to [`gem_spec_paths.rb`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/decidim-restfull-core/lib/decidim/rest_full/core/gem_spec_paths.rb) `GEMS`
- Add `Configuration.enable_<feature>_api` and `available_permissions` in [`configuration.rb`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/decidim-restfull-core/lib/decidim/rest_full/core/configuration.rb)
- Run `./bin/check` in Docker

## When something breaks

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| 404 on new path | Routes registered after first draw | [Boot and extension](./boot-and-extension.md) — initializer order or append API |
| Scope missing on token | Scopes registered too late | `before: "rest_full.scopes"`; see [Scopes and permissions](./scopes-and-permissions.md) |
| OpenAPI path missing | RSwag glob not registered | `ext.rswag_specs` + regenerate — [Generate clients](./generate-clients.md) |

## See also

- [Boot and extension](./boot-and-extension.md) — boot order, `Extension.register`, append API
- [RestFull engines](./restfull-engines.md) — gem layout
- [CONTRIBUTING.md](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/CONTRIBUTING.md) — covenant and `./bin/check`
