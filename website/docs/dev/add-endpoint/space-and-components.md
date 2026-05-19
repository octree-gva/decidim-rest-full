---
title: Spaces and components
sidebar_position: 12
---

## Overview

Participatory content is addressed by **space** + **component**. Core serves **`/spaces`** and **`/components/search`**; feature gems add manifest routes and serializers.

## When to use

- You expose component-backed CRUD (blogs, proposals, forms).
- You only need OpenAPI component shapes (adapter gems).

## Example

### 1. Subclass `Core::ResourcesController`

`decidim-restfull-blogs/app/controllers/decidim/api/rest_full/blogs/blogs_controller.rb`

```ruby
class BlogsController < Decidim::Api::RestFull::Core::ResourcesController
```

### 2. Scope with `filter_for_context`

```ruby
def collection
  query = filter_for_context(model_class.all)
  query = query.where(decidim_component_id: params.require(:component_id)) if params.key?(:component_id)
  ordered(query)
end
```

Uses `ParticipatorySpaceVisibility` — do not bypass for public listings.

### 3. Require participatory query params in specs

`decidim-restfull-blogs/spec/requests/decidim/api/rest_full/blogs/blogs_controller_show_spec.rb`

```ruby
let(:component_id) { component.id }
let(:space_id) { participatory_process.id }
let(:space_manifest) { "participatory_processes" }
```

### 4. Serializer-only adapter (no routes)

Register OpenAPI component schema + permissions in the engine; clients discover the component via `GET /components/search`. Debates, meetings, budgets follow this pattern.

### 5. Optional component manifest routes

`decidim-restfull-blogs/lib/decidim/rest_full/blogs/engine.rb`

```ruby
resources :components, only: [] do
  collection do
    resources :blog_components,
              only: [:index, :show],
              controller: "/decidim/api/rest_full/components/blog_components"
  end
end

resources :blogs,
          only: [:index, :show],
          controller: "/decidim/api/rest_full/blogs/blogs"
```

## Rules

| Rule | Detail |
|------|--------|
| Visibility | Same rules as proposals/blogs — no public bypass in `filter_for_context`. |
| Adapter gems | Schemas + permissions only; no participatory list route. |
| Component CRUD | `GET` uses conditional GET — [HTTP cache](./http-cache.md). |

## Related specs

| Case | Path |
|------|------|
| Space show | `decidim-restfull-core/spec/requests/.../spaces/spaces_controller_show_spec.rb` |
| Proposal components | `decidim-restfull-proposals/spec/requests/.../proposal_components_controller_index_spec.rb` |

## See also

- [Controllers](./controllers.md)
- [Serializations](./serializations.md)
