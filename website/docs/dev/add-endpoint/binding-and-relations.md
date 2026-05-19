---
title: Binding and relations
sidebar_position: 7
---

## Overview

**`rest_enhancement`** adds serializer fields and optional **HTTP cache** contributors for an extension without editing core serializers.

## When to use

- Another gem augments proposal show (or similar) with extra relationships or meta.
- You must keep **304** correct when added data changes.

## Example

### 1. Register `rest_enhancement` in the engine

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
Decidim::RestFull::Extension.register(:widgets) do |ext|
  ext.rest_enhancement(
    serializer: "Decidim::Api::RestFull::Proposals::ProposalSerializer",
    http_cache_profile: :proposal_show
  ) do |e|
    # step 2–3
  end
end
```

`http_cache_profile` must match the controller fingerprint (`:proposal_show`, `:resource_show`, …).

### 2. Declare relationships, meta, or attributes

```ruby
ext.rest_enhancement(
  serializer: "Decidim::Api::RestFull::Proposals::ProposalSerializer",
  http_cache_profile: :proposal_show
) do |e|
  e.has_many :widgets,
             serializer: Decidim::Api::RestFull::Widgets::WidgetSerializer do |proposal, _params|
    proposal.widgets
  end
end
```

### 3. Register `http_cache` when extra tables affect the body

```ruby
e.http_cache do |h|
  h.cache_time { |proposal| proposal.widgets.maximum(:updated_at) }
  h.etag_segment { |proposal| proposal.widgets.count }
end
```

Without `cache_time` / `etag_segment`, clients can get stale **304** responses.

### 4. Rely on strict mode in CI

`spec/spec_helper.rb` sets `strict_rest_enhancement_http_cache` when `ENV["CI"]=1`.

## Rules

| Rule | Detail |
|------|--------|
| Profile | Must match controller fingerprint profile. |
| Missing cache facet | Stale **304**; CI warns or fails when strict. |
| Registry | `FingerprintContributorRegistry` + `SerializerAdditionsRegistry` |

## Related specs

| Case | Path |
|------|------|
| Conditional GET | `decidim-restfull-core/spec/requests/.../jobs/api_jobs_async_and_conditional_get_spec.rb` |

## See also

- [HTTP cache](./http-cache.md)
- [Serializations](./serializations.md)
