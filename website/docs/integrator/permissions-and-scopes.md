---
sidebar_position: 2
title: Permissions and scopes
description: OAuth scopes, fine-grained permissions, and credential storage expectations.
---

# Permissions and scopes

OAuth **scopes** gate route families; **permissions** gate actions inside a scope. Both are fixed on the API client (scopes at creation; permissions editable in System admin or via CLI).

## Auth flows

| Flow | When | Typical scopes |
|------|------|----------------|
| [Client credentials](/user_documentation/auth/client-credential-flow) | Machine-to-machine | `public`, `proposals`, `blogs`, `attachments`, … |
| [Resource owner / impersonation](/user_documentation/auth/user-credential-flow) | Act as a participant or admin user | Same scopes; token includes `resource_owner_id` |

Some operations require a **user** on the token (e.g. voting). Service tokens may act as the first org admin where the API allows it.

## Common matrix (integrator paths)

| Goal | Scope | Permission(s) |
|------|-------|----------------|
| Search components | `public` | `public.component.read` |
| List/read proposals | `proposals` | `proposals.read` |
| Create/update drafts | `proposals` | `proposals.draft` |
| Vote | `proposals` | `proposals.vote` |
| Publish draft | `proposals` | `proposals.draft` (+ route-specific rules) |
| Blogs CRUD | `blogs` | `blogs.read`, `blogs.write`, `blogs.destroy` |
| Attachments | `attachments` | `attachments.read`, `attachments.write`, `attachments.destroy` |
| Webhook delivery | (subscription keys) | Event permission on client, e.g. `proposal_creation.succeeded` |

Webhook **subscriptions** use the same permission strings as in the [Webhooks](./webhooks.md) catalog.

## API client secret lifecycle (Decidim side)

1. **Create** client (UI or `api-client create`) — store `client_id` / `client_secret` on **your** system only.
2. **Use** — obtain short-lived Bearer tokens via `/oauth/token`.
3. **Rotate** — generate a new secret in System admin (or recreate client); update your integration.
4. **Revoke** permissions with `api-client revoke` when narrowing access.
5. **Delete** client with `api-client delete --id …` when decommissioning.

We do **not** store integrator CMS passwords or third-party API keys inside Decidim. Use your platform’s vault (env vars, KMS, encrypted options table).

## Multi-tenant reminder

Tokens are issued for the organization resolved from `Host`. The same `client_id` on two hosts refers to two different OAuth applications if configured per org.
