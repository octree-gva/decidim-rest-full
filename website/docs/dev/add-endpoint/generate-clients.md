---
title: Generate clients and OpenAPI
sidebar_position: 16
---

## Overview

The HTTP contract is **`website/static/openapi.json`**. RSwag request specs generate it; ReDoc serves it at `/api/`.

The TypeScript client (`contrib/decidim-node-client`, `@octree/decidim-sdk`) is generated from this file. See [TypeScript SDK](../../integrator/typescript-sdk).

## When to use

- After any route, schema, or security change.
- Before release, CI, or publishing the doc site.

## Example

### 1. Add or update request specs

See [RSwag](./rswag.md) — every route needs a spec under `decidim-restfull-<gem>/spec/requests/decidim/api/rest_full/`.

### 2. Register OpenAPI schemas

See [Test definitions](./test-definitions.md) — `ext.open_api_definitions` + `DefinitionRegistry`.

### 3. Regenerate the spec file

```bash
docker compose exec rest_full bash -lc 'cd /home/module && yarn gen:openapi-spec'
```

Writes `website/static/openapi.json` via `bin/openapi-stale --yes` → `bin/swaggerize`.

### 4. Validate the spec (optional)

```bash
yarn openapi-generator-cli validate -i website/static/openapi.json
```

### 5. Generate the Node client (optional)

```bash
yarn gen:node-client
```

Output: `contrib/decidim-node-client`.

### 6. Commit and run the full gate

```bash
git add website/static/openapi.json
yarn postcommit
```

CI stale check without generating:

```bash
bin/openapi-stale --check -o website/static/openapi.json
```

Subset of specs only:

```bash
export DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS="decidim-restfull-forms/spec/requests/decidim/api/rest_full/forms/**/*_spec.rb"
bin/swaggerize --out /tmp/openapi.json
```

### Host app (merged spec)

Decidim **host applications** ship extra paths via `Extension.register` in an initializer. They merge the monorepo base OpenAPI with local RSwag specs instead of re-running every gem spec. See [Host app extensions](../host-app-extension.md).

## Rules

| Rule | Detail |
|------|--------|
| No hand-edited paths | Missing route = missing RSwag example. |
| Stale check | `bin/openapi-stale --check` / `yarn gen:openapi-spec:check` for CI. |
| `operationId` | `{verb}{Resource}` camelCase: `listAssemblies`, `showAssembly`, `getProposal`, `castProposalVote`. No snake_case (`proposal_component`). No bare nouns (`users` → `listUsers`). |
| Security | Use `describe_api_endpoint` — sets `credentialFlowBearer` / `resourceOwnerFlowBearer`. Do not duplicate an `Authorization` header parameter in OpenAPI. |
| Responses | Every `200` / `202` must `$ref` a named schema (examples alone do not generate TypeScript types). |
| Request bodies | Named payloads (`:blog_post_create_payload`, `:questionnaire_update_body`), not `type: :object`. |
| Relationships | Use `item_schema_key: :component_relationship_identifier` (or `:resource_relationship_identifier`) in `has_many_relation` to avoid `HasManyRelationItem1` in clients. |
| Async `202` | `$ref` `:rest_full_api_job_accepted` or `:submission_request_accepted_response`. |
| OAuth token | `$ref` `:oauth_token_response` on `createToken` 200. |
| Errors | Reuse `:error_response`, `:forms_validation_error_response`. |
| Full pipeline | `yarn postcommit` — format, openapi, node client, ReDoc HTML. |

## Related specs

| Case | Path |
|------|------|
| Swagger paths | `decidim-restfull-core/spec/lib/decidim/rest_full/core/swagger_spec_paths_spec.rb` |
| Example | `decidim-restfull-proposals/spec/requests/.../proposals_controller_show_spec.rb` |

## See also

- [RSwag](./rswag.md)
- [Test definitions](./test-definitions.md)
- [Command-line tools](../command-line-tools.md)
- [TypeScript SDK](../../integrator/typescript-sdk)
