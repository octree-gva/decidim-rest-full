---
title: Routing
sidebar_position: 2
---

## Overview

Feature routes append to the API mount via **`ext.routes`** inside `Extension.register`. Core routes are in `decidim-restfull-core/config/routes.rb`.

## When to use

- You expose new paths for a feature gem.
- You add **`/sync`** aliases for async mutations.

## Example

### 1. Declare routes inside `ext.routes`

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
ext.routes do
  constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_widgets_api }) do
    resources :widgets,
              only: [:index, :show],
              controller: "/decidim/api/rest_full/widgets/widgets"
  end
end
```

### 2. Use an absolute controller path

`controller: "/decidim/api/rest_full/<feature>/<controller>"` — never a relative controller name.

### 3. Wire default mutation actions to async controllers

`create`, `update`, `destroy` map to controller actions that call `enqueue_rest_full_api_job!` (see [Async](./async.md)).

### 4. Add `/sync` routes for inline responses

`decidim-restfull-proposals/lib/decidim/rest_full/proposals/engine.rb` (draft proposals):

```ruby
resources :draft_proposals,
          only: [:create, :update, :destroy],
          controller: "/decidim/api/rest_full/draft_proposals/draft_proposals" do
  collection do
    post "/sync", action: :create_sync
  end
  member do
    put "/sync", action: :update_sync
    delete "/sync", action: :destroy_sync
    post "/publish", action: :publish
    post "/publish/sync", action: :publish_sync
  end
end
```

Forms authoring (`decidim-restfull-forms/lib/decidim/rest_full/forms/engine.rb`):

```ruby
resources :questions, only: [:create, :update, :destroy],
                      controller: "/decidim/api/rest_full/forms/questions" do
  collection { post "sync", action: :create_sync }
  member do
    put "sync", action: :update_sync
    delete "sync", action: :destroy_sync
  end
end
```

### 5. Register the same `command_key` on engine and controller

`decidim-restfull-proposals/lib/decidim/rest_full/proposals/engine.rb`

```ruby
ext.api_job "draft_proposals#create", ->(ctx, p) {
  Proposals::DraftProposalsOperations.new(ctx, p).create!
}
```

Controller: `enqueue_rest_full_api_job!("draft_proposals#create")` with the **identical** string.

### 6. Register RSwag spec globs

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
ext.rswag_specs(
  File.join(Widgets::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/widgets/**/*_spec.rb")
)
```

## Rules

| Rule | Detail |
|------|--------|
| No duplicate paths | Last drawn route wins; use `rails routes --all` to check before adding your own. |
| Constraints | Wrap in `constraints(-> { Configuration.enable_*_api })` when gated. |
| Forms pattern | See `decidim-restfull-forms/lib/decidim/rest_full/forms/engine.rb` for async + sync member routes. |

## Related specs

| Case | Path |
|------|------|
| Sync routes | `decidim-restfull-proposals/spec/requests/.../draft_proposals_controller_create_spec.rb` |
| Route boot | `decidim-restfull-core/spec/requests/.../routes_boot_spec.rb` |

## See also

- [Async](./async.md)
- [Controllers](./controllers.md)
