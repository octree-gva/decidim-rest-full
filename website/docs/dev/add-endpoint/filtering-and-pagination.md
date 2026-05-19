---
title: Filtering and pagination
sidebar_position: 11
---

## Overview

List endpoints accept **`page`**, **`per_page`**, **`locales[]`**, and **`filter[...]`**. Controllers scope relations to organization and visibility before applying filters.

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

Org-scoped lists use `current_organization` instead of `filter_for_context`.

### 2. Apply `filter[...]` from params

Use Ransack (`filtered(collection)`) or explicit `where` on `params[:filter]`.

### 3. Paginate the relation

```ruby
def index
  page = paginate(ordered(filtered(collection)))
  payload = WidgetSerializer.new(page, params: serializer_params).serializable_hash
  render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(page))
end
```

### 4. Pass locales into serializer params

```ruby
def serializer_params
  { locales: available_locales, host: current_organization.host, act_as: }
end
```

### 5. Document pagination and filters in RSwag

`decidim-restfull-core/spec/requests/decidim/api/rest_full/roles/roles_controller_index_spec.rb`

```ruby
it_behaves_like "paginated params"
it_behaves_like "filtered params", filter: "user_id", item_schema: { type: :integer }, only: :integer
```

Forms index filter:

```ruby
parameter name: "filter[questionnaire_id]", in: :query, schema: { type: :integer }, required: true
let(:"filter[questionnaire_id]") { questionnaire.id }
```

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
| RSwag filter examples | `it_behaves_like "filtered params", filter: "…", only: :string` |
| Extended data | User filters via `UserExtendedDataRansack` — [Models and migrations](./models-and-migrations.md). |
| Collection fingerprint | Index ETag includes filter hash via `collection_fingerprint_for`. |

## Related specs

| Case | Path |
|------|------|
| Components search | `decidim-restfull-core/spec/requests/.../components/components_controller_search_spec.rb` |
| User extended data | `decidim-restfull-core/spec/requests/.../users/user_extended_data_controller_index_spec.rb` |

## See also

- [HTTP cache](./http-cache.md)
- [Space and components](./space-and-components.md)
