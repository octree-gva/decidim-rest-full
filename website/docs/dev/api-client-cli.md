---
sidebar_position: 6
title: API client CLI
description: Technical reference for the decidim-rest_full api-client binstub (provisioning automation).
---

# API client CLI

The `api-client` executable provisions and inspects **API clients** from the shell. It is optional; most admins use the **System** UI ([API clients](/user_documentation/client-api-admin)).

For how it fits with `bin/swaggerize` and client generators, see [Command-line tools](./command-line-tools.md). The script lives at **`exe/api-client`** in the repository.

## Setup

```ruby
bundle binstub decidim-rest_full
```

The binary is placed under `bin/`; ensure it is on your `PATH`.

:::info
Disable the binstub entirely with `DISABLE_REST_FULL_BIN=true` if your deployment must not ship this helper.
:::

## Commands

### `api-client create`

Create a client with the given scopes and optional permissions.

| Option | Description |
|--------|-------------|
| `--scope` | One or more OAuth scopes. Required. |
| `--organization-id` | Decidim organization for the credential. Optional when the only scope is `system`; otherwise required. |
| `--permission` / `--perm` | One or more permissions; must be valid for the chosen scopes. Optional (default: none). |
| `--id` | Fixed `client_id`. Optional. |
| `--secret` | Fixed secret. Optional. |
| `--allow-impersonate` | Client may impersonate participants (when policy allows). |
| `--allow-login` | Client may use login-style ROPC. |
| `--name` | Display name. |
| `--format` | `json` (default) or `text`. |

:::note
1. `api-client create` grants **no permissions** unless you pass `--permission`.
2. `organization-id` is optional only when scopes are **exclusively** `system`.
:::

```bash
api-client create --help
```

```bash
api-client create --scope system
```

```bash
api-client create --scope system --permission system.organizations.update
```

```bash
api-client create --scope blogs --permission blogs.read --organization-id 2
```

```bash
api-client create --scope system --permission system.organizations.update --permission system.organizations.read --id sysadmin-org --secret my-insecure-password
```

### `api-client get`

Fetch one client by id or list all.

| Option | Description |
|--------|-------------|
| `--id` | Client id; omit to list. |

```bash
api-client get --help
```

```bash
api-client get
```

```bash
api-client get --id MOu0W2AAEO8Lp3RrwRqq5dC4AS2_qPuq0WOBpzMgpRA
```

### `api-client grant`

Add a permission to an existing client.

| Option | Description |
|--------|-------------|
| `--id` | Required. |
| `--permission` / `--perm` | Required; must match the client’s scopes. |

```bash
api-client grant --help
```

```bash
api-client grant --id MOu0W2AAEO8Lp3RrwRqq5dC4AS2_qPuq0WOBpzMgpRA --permission blogs.read
```

### `api-client revoke`

Remove a permission from a client.

| Option | Description |
|--------|-------------|
| `--id` | Required. |
| `--permission` / `--perm` | Required. |

```bash
api-client revoke --help
```

```bash
api-client revoke --id MOu0W2AAEO8Lp3RrwRqq5dC4AS2_qPuq0WOBpzMgpRA --permission blogs.read
```

### `api-client delete`

Delete a client, its access tokens, permissions, and webhook registrations.

| Option | Description |
|--------|-------------|
| `--id` | Required. Client id. |

```bash
api-client delete --id MOu0W2AAEO8Lp3RrwRqq5dC4AS2_qPuq0WOBpzMgpRA
```

Exit code is **non-zero** on validation errors (unknown id, missing `--id`, invalid permission).

## Secret lifecycle

1. **Create** — capture `client_id` / `client_secret` once; store on the integrator side only.
2. **Token use** — prefer short-lived Bearer tokens from `/oauth/token`.
3. **Rotate** — new secret in System admin or recreate the client; update your deployment.
4. **Narrow access** — `revoke` permissions or remove scopes by recreating the client.
5. **Delete** — `api-client delete` when the integration is retired.

Do not upload `client_secret` or third-party credentials into Decidim via the API. See [Integrator permissions](/integrator/permissions-and-scopes).
