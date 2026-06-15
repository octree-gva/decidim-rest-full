---
sidebar_position: 1
title: Monorepo architecture
---

# Monorepo architecture

Technical layout of the Rubygems in this repository. For a non-developer summary of behavior, see the [overview](/).

## Gems

| Gem | Role |
|-----|------|
| **decidim-restfull** | Metagem: `require "decidim-restfull"` loads core plus every official `decidim-restfull-*` feature adapter. No `app/` code. |
| **decidim-restfull-core** | OAuth, `ApplicationController`, registries, system routes, jobs, `Extension` DSL, shared serializers. |
| **decidim-restfull-proposals** | Proposals API; `Extension.register(:proposals)` (scopes, routes, jobs, webhooks). |
| **decidim-restfull-blogs** | Blogs API; `Extension.register(:blogs)`. |
| **decidim-restfull-meetings** | Meetings serializers + upcoming-meeting webhook; **`decidim_rest_full_meetings.en.yml`** (scopes, permissions, webhook label); `Extension.register(:meetings)`. |
| **decidim-restfull-debates**, **surveys**, **budgets**, **accountabilities**, **sortition** | Embedded serializers + `*.read` permission + **`decidim_rest_full_*.en.yml`**; OpenAPI manifest schema via `test_definitions.rb`. Sortition ships as **decidim-restfull-sortition** (`Decidim::RestFull::Sortition::Engine`). |
| **decidim-restfull-dev** | Development only: swagger CLI, test helpers. |

Feature gems depend on **decidim-restfull-core** and the matching **decidim-\*** component gem (for example `decidim-surveys`).

## Host Gemfile

```ruby
gem "decidim-restfull"                    # metagem: core + all official adapters

# Or pick slices:
gem "decidim-restfull-core"
gem "decidim-restfull-proposals"
gem "decidim-restfull-blogs"
gem "decidim-restfull-meetings"
gem "decidim-restfull-debates"
gem "decidim-restfull-surveys"
gem "decidim-restfull-forms"
gem "decidim-restfull-budgets"
gem "decidim-restfull-accountabilities"
gem "decidim-restfull-sortition"
```

## Extension DSL

Third-party and first-party feature gems register in an engine initializer (see **decidim-restfull-blogs** and **decidim-restfull-proposals** for full examples; **decidim-restfull-meetings** adds `ext.webhooks` with a custom handler).

- Use **`ext.oauth_scopes`** when the OAuth scope is **not** already listed in `core_optional_scopes` inside `decidim-restfull-core/lib/decidim/rest_full/core/engine.rb` (`:meetings`, `:debates`, … are already there; add scopes for e.g. `:budgets`, `:surveys`).
- Pair each scope with **`ext.permissions(scope, "...read", group:)`** so System Admin can grant abilities; extend **`Ability`** when the slice gates model access.
- Add **`available_permissions`** keys in `Core::Configuration` for CLI validation (`Decidim::RestFull.config.available_permissions`; scope string must match the OAuth scope).

```ruby
Decidim::RestFull::Extension.register(:proposals) do |ext|
  ext.oauth_scopes :proposals
  ext.permissions(:proposals, "proposals.read", group: :proposals)
  ext.routes { ... }
  ext.api_job "draft_proposals#create", ->(ctx, p) { ... }
  ext.rswag_specs File.join(Proposals::ENGINE_ROOT, "spec/requests/.../proposals/**/*_spec.rb")
end
```

Contributor procedures: [Recipe](website/docs/dev/add-endpoint/recipe.md) (start here), then [Add an endpoint](website/docs/dev/add-endpoint/) topic pages.

## Serializer lookup

`Decidim::Api::RestFull::Core::SerializerLookup` resolves `*_ComponentSerializer` namespaces from each component manifest (`proposals` → **Proposals**, `meetings` → **Meetings**, …). Gems place serializers under `app/serializers/decidim/api/rest_full/<Namespace>/`.

## Locales (feature gems)

Scope labels (`scope_<manifest>` under `decidim.rest_full.models.api_client.fields`) and API permission/webhook checkbox strings (`permission.*`) for a slice belong in **`config/locales/decidim_rest_full_<gem-suffix>.en.yml`** beside that gem (same idea as **decidim-restfull-blogs** / **decidim-restfull-proposals**). **decidim-restfull-core** keeps tenant-agnostic UI (forms, system chrome, OAuth/public/system permission groups).

## OpenAPI coverage (component-only gems)

`bin/swaggerize` loads **`spec/rest_full_swagger_spec_paths.rb`**, which registers every gem’s `spec/requests/**/*_spec.rb` via **`Decidim::RestFull::Core::GemSpecPaths`**. Shared component/space coverage lives in **decidim-restfull-core** (`components_controller_search_spec.rb`, `spaces/**/*_spec.rb`). Each feature gem registers **`ext.rswag_specs File.join(ENGINE_ROOT, "spec/requests/...")`** when Rails boots (duplicate registration is harmless).

## Routes

Boot order: load gems → each `Extension.register` runs (engine initializer **`before: "rest_full.draw_routes"`**) → core calls **`Decidim::RestFull::Routes.draw!`** on `Decidim::Core::Engine.routes` at `after_initialize`. Late registration appends via **`Routes.append_pending!`**. See [Boot and extension](./add-endpoint/boot-and-extension.md).

Monorepo route-bearing gems use **`Decidim::RestFull::Routing`** (`read_resources`, `async_resources`). HTTP paths are unchanged — only declaration moves.

Host apps register in `after_initialize`; `Extension.register` appends routes when the app is already initialized. See [Host app extensions](./host-app-extension.md).

## CI

GitLab runs RSpec per gem, then the full metagem suite. Local parity: `./bin/check` inside the `rest_full` Compose service (see repo `CONTRIBUTING.md`).

## Deferred hardening

Async job polling may still have cross-tenant edge cases. Treat org configuration as the isolation boundary until a dedicated hardening pass.

## Related

- [Add an endpoint](./add-endpoint/) — routes, controllers, async, cache, OpenAPI, tests
- [Async writes and jobs](./add-endpoint/async.md)
- [HTTP cache](./add-endpoint/http-cache.md)
- [Binding and relations](./add-endpoint/binding-and-relations.md)
