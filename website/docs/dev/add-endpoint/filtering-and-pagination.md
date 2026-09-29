---
title: Filtering and pagination
sidebar_position: 13
---

## Overview

List endpoints accept **`page`**, **`per_page`**, **`locales[]`**, and **`filter[...]`**. Controllers scope relations to organization and visibility before applying filters.

Every collection **index** / **search** response uses the same offset-pagination envelope (no cursor, no counts):

```json
{
  "data": [ /* serialized records */ ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "has_more": true,
    "next": "https://host/api/rest_full/v0.3/<resource>?page=2&per_page=20",
    "prev": null
  }
}
```

| Field | Rule |
|-------|------|
| `page` | Integer ≥ 1 (default `1`) |
| `per_page` | Default `20`, hard cap `100`; invalid/≤0 → `20` |
| `has_more` | From **limit+1** (fetch `per_page + 1`, drop the extra). Never `COUNT(*)` |
| `next` / `prev` | Absolute URLs preserving all query params; `null` when inapplicable |
| Forbidden | `count`, `total_count`, `total_pages`, `total`, and pagination `Total` headers |

Forms indexes that already expose locale meta merge locale keys into the same `meta` object (`forms_collection_meta`).

## When to use

- You add or change an **index** or **search** action.
- You need custom filter keys (Ransack or manual predicates).

## Example

### 1. Start from a scoped collection

`decidim-restfull-blogs/app/controllers/decidim/api/rest_full/blogs/blogs_controller.rb`

```ruby
def collection
  query = filter_for_context(model_class.order(published_at: :asc))
  query = query.where(decidim_component_id: params.require(:component_id)) if params.key?(:component_id)
  ordered(query)
end
```

Org-scoped lists use `current_organization` instead of `filter_for_context`. Stable sorts must end with an `id` tie-breaker (`ResourcesController#ordered` does this via `order_string`).

### 2. Apply `filter[...]` from params

Use Ransack (`filtered(collection)`) or explicit `where` on `params[:filter]`.

### 3. Paginate with the shared helper

```ruby
def index
  scoped = ordered(filtered(collection))
  records, meta = paginate_collection(scoped)
  payload = WidgetSerializer.new(records, params: serializer_params).serializable_hash
  payload[:meta] = meta
  render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(scoped))
end
```

`paginate_collection` lives in `Decidim::Api::RestFull::CollectionPagination` (included on `ApplicationController`). Prefer fingerprinting the **unpaginated** scope (strip `RANDOM()` order when needed).

### 4. Pass locales into serializer params

```ruby
def serializer_params
  { locales: available_locales, host: current_organization.host, act_as: }
end
```

### 5. Document pagination and filters in RSwag

```ruby
it_behaves_like "paginated params"
it_behaves_like "paginated endpoint"
it_behaves_like "filtered params", filter: "user_id", item_schema: { type: :integer }, only: :integer
```

Index schemas come from `DefinitionRegistry#register_response_for` (`data` + `collection_meta`).

### 6. Register new Ransack attributes in core

`decidim-restfull-core/lib/decidim/rest_full/core/ransackers.rb`

```ruby
Decidim::User.class_eval do
  ransacker :my_custom_field do
    Arel.sql("decidim_users.extended_data->>'my_key'")
  end
end
```

## Rules

| Rule | Detail |
|------|--------|
| No unscoped queries | Never list rows without org + ability scope. |
| Shared helper only | Do not reimplement pagination or use `api-pagination` / Kaminari `page.per` for index bodies. |
| No counts | Never `COUNT(*)` for pagination or collection ETags. |
| RSwag filter examples | `it_behaves_like "filtered params", filter: "…", only: :string` |
| Extended data | User filters via `UserExtendedDataRansack` — [Models and migrations](./models-and-migrations.md). |
| Collection fingerprint | Index ETag includes `page`, `per_page`, filter, `order` / `order_direction` — not counts. |

## Related specs

| Case | Path |
|------|------|
| Shared pagination examples | `decidim-restfull-core/lib/decidim/rest_full/test/shared_examples.rb` |
| Helper unit specs | `decidim-restfull-core/spec/controllers/concerns/.../collection_pagination_spec.rb` |
| Components search | `decidim-restfull-core/spec/requests/.../components/components_controller_search_spec.rb` |

## See also

- [HTTP cache](./http-cache.md)
- [Space and components](./space-and-components.md)
