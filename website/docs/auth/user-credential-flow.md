---
sidebar_position: 4
title: User Token
description: How to authenticate a user to Decidim API.
---

# User Authentication (Resource Owner Password Flow)

This flow allows you to authenticate on behalf of a user, granting access to user-specific data in the Decidim API.
With a ROPC token, you can for example: 
- Create a proposal in behalf of a user
- Follow an assembly in behalf of a user
- Comment
- etc.

This authentication is the default one for most of the endpoints, expect the `system` endpoints that requires a machine-to-machine token.

## Authentication type
The ROPC flows allows two kind of authentication, use the auth_type attribute to define the kind of ROPC you want to do. 
- `impersonate`: just give a username, it will upsert a user, and act as the user. 
- `login`: give a username/password, and start acting as the user.

## How to Get a Token

Use the `grant_type=password` with user credentials to request an access token. Ensure your OAuth application has the correct client ID, client secret, and scopes.

### Required Parameters

- **`grant_type`**: Must be `password`.
- **`auth_type`**: Defines the impersonation type (`login` or `impersonate`).
- **`username`**: The user's unique identifier (e.g., nickname or email).
- **`password`**: The user's password.
- **`client_id`**: Your OAuth application Client ID.
- **`client_secret`**: Your OAuth application Client Secret.
- **`scope`**: The permissions requested (e.g., `public proposals`).

### Example with `curl`

```bash
curl -X POST https://<organization-host>/oauth/token \
-H "Content-Type: application/json" \
-d '{
  "grant_type": "password",
  "auth_type": "impersonate",
  "username": "<user_nickname>",
  "client_id": "<client_id>",
  "client_secret": "<client_secret>",
  "scope": "public proposals"
}'
```

### Example Reponse
```json
{
  "access_token": "<token>",
  "token_type": "Bearer",
  "expires_in": 7200,
  "scope": "public proposals"
}
```

## Error Handling
### Invalid Credentials
```json
{
  "error": "invalid_grant",
  "error_description": "The provided authorization grant is invalid, expired, or revoked."
}
```
### Unauthorized Scope
```json
{
  "error": "invalid_scope",
  "error_description": "The requested scope is invalid, unknown, or malformed."
}
```