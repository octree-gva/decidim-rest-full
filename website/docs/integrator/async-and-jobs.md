---
sidebar_position: 3
title: Async and jobs
description: 202 responses, job polling, and sync vs async routes.
---

# Async and jobs

Some writes return **HTTP 202** with a `job_id` instead of completing inline.

## Sequence

1. `POST` (or `PUT` / `DELETE`) async route → **202** + `job_id` (UUID).
2. `GET /jobs/{id}` — **no Bearer required**; the UUID is the capability.
3. Optional: `GET /jobs` with Bearer (same OAuth app + resource owner) to list/filter.
4. Optional: `DELETE /jobs/{id}` to drop completed/failed rows.

## Sync vs async (common resources)

| Resource | Async example | Sync example |
|----------|---------------|--------------|
| Draft proposals | `POST /draft_proposals` | `POST /draft_proposals/sync` |
| Publish draft | `POST /draft_proposals/{id}/publish` | `POST …/publish/sync` |
| Blogs | `POST /blogs` | `POST /blogs/sync` |
| Forms (questionnaire) | async mutations | `PUT …/sync` |
| Attachments | — | sync only in v1 (`POST /attachments`) |
| Roles | `POST /roles` | `POST /roles/sync` |

Use **sync** routes when your integration needs an immediate body or error. Use **async** for long work or when you prefer polling.

Filter jobs: `filter[command_key]` (e.g. `draft_proposals#create`), `filter[status]` (`pending`, `processing`, `completed`, `failed`).

See OpenAPI **Jobs** tag for schemas.
