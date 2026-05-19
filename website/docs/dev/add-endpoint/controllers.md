---
title: Controllers
sidebar_position: 5
---

## Overview

Controllers live under `app/controllers/decidim/api/rest_full/`. They authorize, call operations or serializers, and render JSON. No business logic in the controller.

## When to use

- You add a new HTTP surface for a feature gem.
- You wire async, sync, or conditional GET behaviour.

## Example

### 1. Subclass the right base controller

Participatory resource: `decidim-restfull-blogs/app/controllers/decidim/api/rest_full/blogs/blogs_controller.rb`

```ruby
class BlogsController < Decidim::Api::RestFull::Core::ResourcesController
```

Org-scoped (no component): `decidim-restfull-core/app/controllers/decidim/api/rest_full/roles/roles_controller.rb`

```ruby
class RolesController < Decidim::Api::RestFull::ApplicationController
```

### 2. Authorize scope and permission

```ruby
before_action { doorkeeper_authorize! :blogs }
before_action { ability.authorize! :read, ::Decidim::Blogs::Post }
```

### 3. Render GETs with conditional cache

```ruby
def show
  @resource = find_resource!
  render_json_with_conditional_get(
    serialized_show(@resource),
    fingerprint: resource_fingerprint_for(@resource)
  )
end
```

See [HTTP cache](./http-cache.md).

### 4. Enqueue mutations (and add `*_sync` when needed)

```ruby
include Decidim::Api::RestFull::AsyncApiJobEnqueuing

def create
  enqueue_rest_full_api_job!("widgets#create")
end
```

See [Async](./async.md).

### 5. Register routes in the engine

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb` — `ext.routes` block. See [Routing](./routing.md).

### 6. Add an RSwag request spec

`decidim-restfull-widgets/spec/requests/decidim/api/rest_full/widgets/widgets_controller_show_spec.rb`

Register the glob:

```ruby
ext.rswag_specs File.join(Widgets::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/widgets/**/*_spec.rb")
```

Participatory specs need `let(:component_id)`, `let(:space_id)`, `let(:space_manifest)`.

## Rules

| Rule | Detail |
|------|--------|
| Thin controllers | Delegate to `*Operations` or serializers. |
| `api_context` / `api_execution_context` | Pass to operations from sync actions and jobs. |
| Organization scope | Users, roles: `current_organization`; not `ResourcesController#filter_for_context`. |
| Component scope | Resources: `component_id`, `space_id`, `space_manifest` query params. |
| Errors | Raised as `ApiException`; handled in `ApplicationController`. |

## Related specs

| Pattern | Path |
|---------|------|
| Component resource | `decidim-restfull-blogs/spec/requests/.../blogs_controller_show_spec.rb` |
| Async + sync | `decidim-restfull-proposals/spec/requests/.../draft_proposals_controller_create_spec.rb` |
| Org-scoped | `decidim-restfull-core/spec/requests/.../roles/roles_controller_index_spec.rb` |

Use **`describe_api_endpoint`** for OpenAPI security metadata.

## See also

- [Routing](./routing.md)
- [Serializations](./serializations.md)
- [RSwag](./rswag.md)
