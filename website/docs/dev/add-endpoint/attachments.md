---
sidebar_position: 18
title: Attachments API
description: Core attachments routes and create modes.
---

# Attachments API (core)

Routes live in `decidim-restfull-core` (`enable_attachments_api`).

| Route | Notes |
|-------|--------|
| `GET/POST /attachments` | List / create |
| `GET/PUT/DELETE /attachments/:id` | Show / metadata update / delete |
| `POST /attachments/direct_upload` | ActiveStorage `signed_id` staging |

**Mode A:** multipart `POST /attachments` — preferred for integrators.

**Mode B:** `direct_upload` + JSON `POST /attachments` with `signed_id` — large files, parity with Decidim admin.

Operations: `Decidim::RestFull::Core::AttachmentsOperations` (wraps `Decidim::Admin::CreateAttachment` / `UpdateAttachment`).

Integrator doc: [Attachments](/integrator/attachments).
