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
| **501** | Feature/module disabled for this org | Enable on System → organization → Restfull Toggle tab |
| **422** | Semantic validation | See message (e.g. form errors) |

## Envelope

```json
{
  "error": "400: Bad request",
  "error_description": "Title is too short (under 15 characters). Body must start with a capital letter",
  "error_details": [
    { "code": "too_short", "field": "title", "description": "Title is too short (under 15 characters)" },
    { "code": "must_start_with_caps", "field": "body", "description": "Body must start with a capital letter" }
  ]
}
```

- `error` / `error_description` are always present (`error_description` may join several messages with `". "`).
- `error_details` is present for draft proposal **update** / **publish** validation failures: one entry per ActiveModel error (`code`, optional `field`, `description`).
- Prefer branching on `error_details[].code` (and `field`) rather than parsing `error_description` text.

### Draft proposal validation codes

| `code` | Typical meaning |
|--------|-----------------|
| `blank` | Title/body empty |
| `too_short` | Under minimum length (title 15, body 15) |
| `too_long` | Over maximum length |
| `must_start_with_caps` | Must start with a capital letter |
| `too_much_caps` | Too many capital letters |
| `too_many_marks` | Too many consecutive punctuation marks |
| `cant_be_equal_to_template` | Body equals the component template |

On **update**, only errors for fields present in the payload are returned.

## Common messages

| Message / situation | Remediation |
|---------------------|-------------|
| Forbidden / CanCan denied | Add permission in System admin (`proposals.draft`, …) |
| User required | Use ROPC/impersonation token with `resource_owner_id` |
| User blocked / locked | Pick another user |
| Already voted | Idempotent vote handling on your side |
| Unknown order / filter | Match OpenAPI allowed values |
| Attachments API disabled | Restfull Toggle `attachments_enabled` for the organization |

## Permissions debugging

1. Confirm **scope** on token includes the route family (`proposals`, …).
2. Confirm **permission** on API client matches the action.
3. Confirm **Host** matches the organization that owns the client.
