---
title: HTTP cache
sidebar_position: 6
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
records, meta = paginate_collection(scoped)
payload = BlogSerializer.new(records, params: serializer_params).serializable_hash
payload[:meta] = meta
```

### 2. Call `render_json_with_conditional_get`

```ruby
render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(scoped))
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
  scoped = ordered(filtered(collection))
  records, meta = paginate_collection(scoped)
  payload = WidgetSerializer.new(records, params: serializer_params).serializable_hash
  payload[:meta] = meta
  render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(scoped))
end
```

Pass the **unpaginated** relation (or array) to `collection_fingerprint_for`. Do not put a relation `COUNT` into the ETag.

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
| Show fingerprint | `ResourceShowFingerprint` — org id, record class, id, `updated_at` (ETag uses subsecond `to_f`), client, locales. |
| Index fingerprint | `CollectionFingerprint` — max timestamp, page, per_page, filter, order, locales — **no** count. |
| `extended_data` | Satellite row uses `belongs_to … touch: true` so parent `updated_at` (and ETag) moves on write. |
| `Rails.cache` | Optional server-side memoization; not a substitute for client validators. |
| `rest_enhancement` | Register `cache_time` / `etag_segment` when extra tables affect the body. |
| Exceptions | `GET /magic_links/:id` redirects (HTML). Error bodies skip cache. |

## Related specs

| Case | Path |
|------|------|
| Proposal show 304 | `decidim-restfull-core/spec/requests/.../jobs/api_jobs_async_and_conditional_get_spec.rb` |
| Proposal show after extended_data | same file — must **not** 304 after `/extended_data/sync` |
| Blog show 304 | `decidim-restfull-blogs/spec/requests/.../blogs_controller_show_spec.rb` |

## See also

- [Controllers](./controllers.md)
- [Binding and relations](./binding-and-relations.md)
