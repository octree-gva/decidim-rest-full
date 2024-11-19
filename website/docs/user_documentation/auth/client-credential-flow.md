---
sidebar_position: 3
title: Machine-to-Machine Token
description: How to authenticate a service to Decidim.
---

![Client Credentials](../../client_cred.png)

# Machine-to-Machine Authentication (Client Credentials Flow)

This flow is used for service-to-service authentication in Decidim, allowing systems to interact with the Decidim API without user involvement.

## How to Get a Token

Use the `grant_type=client_credentials` to request an access token. Ensure your OAuth application is configured with the necessary client ID, client secret, and scopes.

### Required Parameters

- **`grant_type`**: Must be `client_credentials`.
- **`client_id`**: Your OAuth application Client ID.
- **`client_secret`**: Your OAuth application Client Secret.
- **`scope`**: The permissions requested (e.g., `system`).

### Example with `curl`

```bash
curl -X POST https://<organization-host>/oauth/token \
-H "Content-Type: application/json" \
-d '{
  "grant_type": "client_credentials",
  "client_id": "<client_id>",
  "client_secret": "<client_secret>",
  "scope": "system"
}'
```
### Example Response
```json
{
  "access_token": "<token>",
  "token_type": "Bearer",
  "expires_in": 7200,
  "scope": "system"
}
```

### Use Case: Listing All Organizations in Decidim
1. Obtain Token: Use the example above to get a token with the system scope.
2. List Organizations: Make an authenticated request to the /api/v1/organizations endpoint:
   ```bash
      curl -X GET https://<organization-host>/api/rest_full/system/organizations \
        -H "Authorization: Bearer <access_token>"
    ```
3. Example Response:
   ```json
        [
            {
                "id": 1,
                "name": "Organization A",
                "host": "org-a.example.com"
            },
            {
                "id": 2,
                "name": "Organization B",
                "host": "org-b.example.com"
            }
        ]
    ```
