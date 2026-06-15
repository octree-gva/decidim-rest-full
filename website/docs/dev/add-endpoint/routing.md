---
title: Routing
sidebar_position: 4
---

## Overview

Feature routes append via **`ext.routes`** inside `Extension.register`. Use **`Decidim::RestFull::Routing`** in monorepo gems (required for new work). Core routes stay in `decidim-restfull-core/config/routes.rb`.

Start with [Recipe](./recipe.md) and [Boot and extension](./boot-and-extension.md) if routes do not appear.

## When to use

- You expose new paths for a feature gem.
- You add **`/sync`** aliases for async mutations.

## Example

### 1. Read-only routes

`decidim-restfull-blogs/lib/decidim/rest_full/blogs/engine.rb`

```ruby
ext.routes do
  constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_blogs_api }) do
    Decidim::RestFull::Routing.read_resources(
      self,
      :blog_components,
      controller: "components/blog_components",
      only: [:index, :show]
    )
  end
end
```

Pass **`self`** (the router inside the block) as the first argument.

### 2. Async CRUD + sync aliases

```ruby
Decidim::RestFull::Routing.async_resources(
  self,
  :blogs,
  controller: "blogs/blogs",
  only: [:index, :show, :create, :update, :destroy]
)
```

`async_resources` adds collection `POST …/sync` and member `PUT/DELETE …/sync` for create/update/destroy in `only:`.

Extra member routes (draft proposal publish):

```ruby
Decidim::RestFull::Routing.async_resources(
  self,
  :draft_proposals,
  controller: "draft_proposals/draft_proposals",
  only: [:index, :show, :create, :update, :destroy],
  member: { post: { publish: :publish, "publish/sync": :publish_sync } }
)
```

### 3. Escape hatch — raw `resources`

Use when the Routing DSL cannot express a route (forms `questionnaire_responses` member `update_forbidden`):

```ruby
resources :questionnaire_responses, only: [:show, :destroy],
                                    controller: "/decidim/api/rest_full/forms/questionnaire_responses" do
  member do
    put "/", action: :update_forbidden
    delete "sync", action: :destroy_sync
  end
end
```

Always use an absolute controller path: `/decidim/api/rest_full/<feature>/<controller>`.

### 4. Register `api_job` and wire the controller

Engine:

```ruby
ext.api_job "draft_proposals#create", ->(ctx, p) {
  Proposals::DraftProposalsOperations.new(ctx, p).create!
}
```

Controller: `enqueue_rest_full_api_job!("draft_proposals#create")` with the **identical** string. See [Async](./async.md).

### 5. Register RSwag spec globs

```ruby
ext.rswag_specs(
  File.join(Widgets::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/widgets/**/*_spec.rb")
)
```

## Rules

| Rule | Detail |
|------|--------|
| Routing DSL | Required for new monorepo gems; raw `resources` only for escape hatches. |
| No duplicate blocks | Same route block registered twice raises `DuplicateRouteBlockError`. |
| Constraints | Wrap `ext.routes` in `constraints(-> { Configuration.enable_*_api })` when gated. |
| Controller path | `Routing` builds `/decidim/api/rest_full/…` from the `controller:` segment. |

## Related specs

| Case | Path |
|------|------|
| Routing DSL | `decidim-restfull-core/spec/lib/decidim/rest_full/routing_spec.rb` |
| Sync routes | `decidim-restfull-proposals/spec/requests/.../draft_proposals_controller_create_spec.rb` |
| Route boot | `decidim-restfull-core/spec/requests/.../routes_boot_spec.rb` |

## See also

- [Boot and extension](./boot-and-extension.md)
- [Async](./async.md)
- [Controllers](./controllers.md)
