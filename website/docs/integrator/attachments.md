---
sidebar_position: 6
title: Attachments
description: Upload files and link them to Decidim resources.
---

# Attachments

Manage `Decidim::Attachment` rows via scope **`attachments`**.

| Permission | Actions |
|------------|---------|
| `attachments.read` | `GET /attachments`, `GET /attachments/{id}` |
| `attachments.write` | `POST /attachments`, `POST /attachments/direct_upload`, `PUT /attachments/{id}` (metadata) |
| `attachments.destroy` | `DELETE /attachments/{id}` |

There is **no** `/uploads` resource — only attachments + optional direct upload staging.

## Mode A — single request (default)

`POST /attachments` as `multipart/form-data`:

- `file` — binary
- `attached_to_type` — e.g. `Decidim::Proposals::Proposal` or alias `proposals`
- `attached_to_id` — parent record id
- `title`, `description` — string for default locale (or JSON:API body)

## Mode B — large files

1. `POST /attachments/direct_upload` with `filename`, `byte_size`, `checksum`, optional `content_type` → `signed_id`.
2. Upload bytes to ActiveStorage using your client (same as Rails direct upload).
3. `POST /attachments` as `application/json` with `signed_id` + `attached_to_*` + metadata.

## List filters

`GET /attachments?filter[attached_to_type]=proposals&filter[attached_to_id]=123`

Also: `filter[attachment_collection_id]`, `filter[file_type]` (`image`, `document`, `link`).

## Update / delete

- `PUT /attachments/{id}` — title, description, weight, collection only (no file swap in v1).
- `DELETE /attachments/{id}` — removes attachment and stored file per Decidim rules.

See OpenAPI **Attachments** tag for request schemas.
