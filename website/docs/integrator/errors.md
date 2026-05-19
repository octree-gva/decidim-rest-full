---
sidebar_position: 5
title: Errors
description: HTTP status codes and common API error messages.
---

# Errors

Responses use JSON with `error` / `error_description` or JSON:API-style `errors` arrays.

## Status codes

| Code | Meaning | Typical fix |
|------|---------|-------------|
| **401** | Missing/invalid/expired token | Refresh via `/oauth/token` |
| **403** | Valid token, forbidden | Grant scope/permission; use user token if required |
| **400** | Bad request / validation | Fix body, filters, or required user |
| **404** | Unknown route or record | Check path, id, host/tenant |
| **422** | Semantic validation | See message (e.g. form errors) |

## Common messages

| Message / situation | Remediation |
|---------------------|-------------|
| Forbidden / CanCan denied | Add permission in System admin (`proposals.draft`, …) |
| User required | Use ROPC/impersonation token with `resource_owner_id` |
| User blocked / locked | Pick another user |
| Already voted | Idempotent vote handling on your side |
| Unknown order / filter | Match OpenAPI allowed values |
| Attachments API disabled | `enable_attachments_api` on host |

## Permissions debugging

1. Confirm **scope** on token includes the route family (`proposals`, …).
2. Confirm **permission** on API client matches the action.
3. Confirm **Host** matches the organization that owns the client.
