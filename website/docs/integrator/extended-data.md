---
title: Extended data
sidebar_position: 4
---

# Extended data

Who reads this: **integrators** attaching client-only metadata to Decidim resources and filtering on it.

## Overview

`extended_data` is a JSON bag for **integration keys, sync markers, and other client metadata**. RestFull keeps it on a related row per resource (same idea as Decidim’s `HasQuestionnaire` / `HasResourcePermission`), so it stays out of the Decidim admin UI.

| Resource | Read/write path | List/search filter |
| --- | --- | --- |
| Organization | `/organizations/{id}/extended_data` | — |
| Component | `/components/{id}/extended_data` | `GET /components/search` |
| Participatory spaces | `/spaces/{manifest}/{id}/extended_data` | `GET /spaces/search`, `GET /spaces/{manifest}` |
| Proposal | `/proposals/{id}/extended_data` | `GET /proposals` |
| Meeting | `/meetings/{id}/extended_data` | `GET /meetings` |

**Users** use Decidim’s built-in user metadata and `/me/extended_data`.

## Query (GET)

```http
GET /components/{id}/extended_data?object_path=.
Authorization: Bearer …
```

- `object_path=.` — full hash
- `object_path=foo.bar` — nested value (missing path → `{}`, HTTP 200)

Response shape: `{ "data": … }`.

## Update (PUT)

Prefer sync while developing:

```http
PUT /components/{id}/extended_data/sync?object_path=.
Content-Type: application/json

{ "data": { "integration": { "id": "abc" } } }
```

Semantics (same as organization extended data):

- Recursive **merge** at `object_path`
- Nested hashes merge; scalars replace
- `null` / empty values **remove** keys after compact
- Unknown paths are created
- Async `PUT …/extended_data` returns **202** + job poll (see [Async and jobs](./async-and-jobs))

## Filter lists

```http
GET /proposals?filter[extended_data_cont]="integration":"abc"
```

Requires the matching `*.extended_data.read` permission. Match is a substring over the stored JSON text (same idea as the user list filter).

## Permissions

Grant `*.extended_data.read` / `*.extended_data.update` on the resource’s OAuth scope (`system` for organizations, `public` for components and spaces, `proposals`, `meetings`, or `oauth` for `/me`). Exact permission strings are listed on each operation in the [API reference](/api).

## OpenAPI

ReDoc documents each operation; tag descriptions link back here.
