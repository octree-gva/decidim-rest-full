---
sidebar_position: 1
title: Quickstart
description: First API call in five steps — host, client, token, component, write.
---

# Integrator quickstart

Reach a successful API call without reading contributor docs.

For **TypeScript**, see [TypeScript SDK](./typescript-sdk) (`@octree/decidim-sdk`).

## 1. Resolve your host

One Decidim deployment serves many **organizations**. The HTTP `Host` header selects the tenant (e.g. `participatory.example.org`).

## 2. Create an API client

**System admin UI:** [API clients](/user_documentation/client-api-admin) — create a client with scopes such as `public`, `proposals`, and grant permissions (`public.component.read`, `proposals.draft`, …).

**CLI (on the server):** see [API client CLI](/dev/api-client-cli).

### Local docker sandbox

After `docker compose up` and `db:seed`:

```bash
docker compose exec rest_full bash -lc 'cd /home/module/spec/decidim_dummy_app && bundle exec rails decidim_rest_full:seed_integrator_sandbox'
```

Stdout is JSON with `host`, `client_id`, `client_secret`, and granted permissions (local dev only — rotate secrets before any shared environment).

## 3. Get a Bearer token

```bash
export HOST=localhost
export CLIENT_ID=integrator-sandbox
export CLIENT_SECRET=integrator-sandbox-secret-change-me

curl -sS -X POST "http://${HOST}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&scope=public proposals"
```

Save `access_token` as `TOKEN`. See [Client credentials](/user_documentation/auth/client-credential-flow).

## 4. Find a component id

```bash
curl -sS "http://${HOST}/api/rest_full/v0.3/components/search?filter[manifest_name]=proposals" \
  -H "Authorization: Bearer ${TOKEN}" | jq .
```

Use the returned `id` as `COMPONENT_ID`. Details: [Resolve component id](./resolve-component-id.md).

## 5. Create and publish a draft (sync)

```bash
export COMPONENT_ID=1

curl -sS -X POST "http://${HOST}/api/rest_full/v0.3/draft_proposals/sync" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"type\":\"draft_proposal\",\"attributes\":{\"title\":{\"en\":\"Hello API\"},\"body\":{\"en\":\"First draft\"},\"component_id\":${COMPONENT_ID}}}}"
```

Publish inline:

```bash
export DRAFT_ID=<id from create response>
curl -sS -X POST "http://${HOST}/api/rest_full/v0.3/draft_proposals/${DRAFT_ID}/publish/sync" \
  -H "Authorization: Bearer ${TOKEN}"
```

For **async** writes (`202` + job polling), see [Async and jobs](./async-and-jobs.md).

## Executable scripts

Copy-paste examples live in [`examples/integrator/`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/tree/main/examples/integrator) at the repository root.

## Next steps

- [Permissions and scopes](./permissions-and-scopes.md)
- [OpenAPI reference](/api) (authoritative paths)
- [Contract changes](./contract-changes.md)
