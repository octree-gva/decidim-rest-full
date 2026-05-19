---
title: HTTP cache
sidebar_position: 4
---

## Overview

JSON **GET** responses use **`render_json_with_conditional_get`** on `ApplicationController`. Clients may send `If-None-Match` / `If-Modified-Since` and receive **304 Not Modified**.

## When to use

- You add or change a **show** or **index** (or **search**) action that returns JSON.
- You extend serializers with data not reflected in `updated_at` (register `http_cache` facets).

## Example

### 1. Build the JSON payload first

`decidim-restfull-blogs/app/controllers/decidim/api/rest_full/blogs/blogs_controller.rb`

```ruby
payload = BlogSerializer.new(page, params: serializer_params).serializable_hash
```

### 2. Call `render_json_with_conditional_get`

```ruby
render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(page))
```

### 3. Fingerprint a show action

```ruby
def show
  @resource = find_resource!
  render_json_with_conditional_get(
    serialized_show(@resource),
    fingerprint: resource_fingerprint_for(@resource)
  )
end
```

### 4. Fingerprint an index or search action

```ruby
def index
  page = paginate(collection)
  payload = WidgetSerializer.new(page, params: serializer_params).serializable_hash
  render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(page))
end
```

Pass a relation, array, or Kaminari page to `collection_fingerprint_for`.

### 5. Use a custom show fingerprint when needed

Proposals: `fingerprint: ProposalShowFingerprint.for_request(self, record)` instead of `resource_fingerprint_for`.

### 6. Add a 304 request spec

`decidim-restfull-blogs/spec/requests/decidim/api/rest_full/blogs/blogs_controller_show_spec.rb` (inside an example):

```ruby
get "/api/rest_full/v1/blogs/#{id}", headers: auth_headers
etag = response.headers["ETag"]
get "/api/rest_full/v1/blogs/#{id}", headers: auth_headers.merge("If-None-Match" => etag)
expect(response).to have_http_status(:not_modified)
```

## Rules

| Rule | Detail |
|------|--------|
| Default | All JSON GETs in `decidim-restfull-*` use conditional GET. |
| Show fingerprint | `ResourceShowFingerprint` — org id, record class, id, `updated_at`, client, locales. |
| Index fingerprint | `CollectionFingerprint` — max timestamp, count, page, filter, locales. |
| `Rails.cache` | Optional server-side memoization; not a substitute for client validators. |
| `rest_enhancement` | Register `cache_time` / `etag_segment` when extra tables affect the body. |
| Exceptions | `GET /magic_links/:id` redirects (HTML). Error bodies skip cache. |

## Related specs

| Case | Path |
|------|------|
| Proposal show 304 | `decidim-restfull-core/spec/requests/.../jobs/api_jobs_async_and_conditional_get_spec.rb` |
| Blog show 304 | `decidim-restfull-blogs/spec/requests/.../blogs_controller_show_spec.rb` |

## See also

- [Controllers](./controllers.md)
- [Binding and relations](./binding-and-relations.md)
