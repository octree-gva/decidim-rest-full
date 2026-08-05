---
title: Models and migrations
sidebar_position: 15
---

## Overview

Who reads this: **contributors** adding persistence or extending Decidim models from a RestFull gem.

API-owned persistence ships as migrations under the gem that owns the feature (usually `decidim-restfull-core/db/migrate`). Domain records stay on Decidim models; extend them with concerns when you need RestFull behaviour.

## When to use

- Persistence only the API layer owns (jobs, client metadata).
- Behaviour on Decidim models via concerns (preferred over parallel domain tables).

## Extended data

Client metadata on organizations, components, spaces, proposals, and meetings is a **related row per resource** (polymorphic association), wired with `Decidim::RestFull::Core::HasExtendedData` — same idea as Decidim `HasQuestionnaire` / `HasResourcePermission`.

1. Include the concern from `config.to_prepare`
2. Read/write through the existing extended_data HTTP surface (see integrator docs)

Users keep Decidim’s built-in user metadata field and `/me/extended_data`.

Integrator docs: [Extended data](/integrator/extended-data).

## Example: scope queries

```ruby
Widget.where(organization: current_organization)
# plus ability checks in the controller
```

## Runtime feature gates

Runtime availability for the org is enforced by `ModuleAvailability` (Toggle).

## Migrations

Add migrations under the owning gem’s `db/migrate`. Refresh the dummy app with `bin/setup-tests`, or run the host app’s `rails db:migrate`.
