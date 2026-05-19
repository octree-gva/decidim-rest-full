---
sidebar_position: 4
title: Resolve component id
description: Find Decidim::Component id via GET /components/search.
---

# Resolve component id

Proposal, blog, and other APIs need a **`component_id`** (`Decidim::Component`).

## Search

```http
GET /api/rest_full/v0.3/components/search?filter[manifest_name]=proposals&filter[participatory_space_id]=42
Authorization: Bearer …
```

Requires scope **`public`** and permission **`public.component.read`**.

## Useful filters

| Filter | Example |
|--------|---------|
| `filter[manifest_name]` | `proposals`, `blogs`, `meetings` |
| `filter[participatory_space_id]` | Participatory process / assembly id |
| `filter[participatory_space_type]` | Manifest of the space |
| `filter[id]` | Exact component id |
| `filter[name]` | Substring on localized name |

## Workflow

1. List or know the participatory space id (from admin UI or `GET /participatory_processes`, etc.).
2. Search components with `manifest_name` + `participatory_space_id`.
3. Use the returned `id` in create payloads (`component_id` attribute).

Only components in **visible** spaces for the token actor are returned.
