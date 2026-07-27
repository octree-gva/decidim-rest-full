---
title: Core concepts
sidebar_position: 6
---

# Core concepts

If you will add or change API endpoints, read this first. Others start at [Ways to contribute](/contribute/ways-to-contribute). Step-by-step guides live under [Developer documentation](/dev/architecture).

## Permissions and scopes

OAuth **scopes** live on the token. **Permissions** (abilities) live on the action. The **permission registry** is filled when a gem calls `ext.permissions` inside `Extension.register` (paired with `ext.oauth_scopes` when the scope is new). System Admin checkboxes and CLI validation read that registry.

Controllers call `doorkeeper_authorize!` first, then `ability.authorize!`.

See also: [Scopes and permissions](/dev/add-endpoint/scopes-and-permissions).

## Webhooks

Register listeners with `ext.webhooks` in the engine. That catalog feeds admin UI and OpenAPI.

Domain events enqueue a job; the job delivers signed HTTP POSTs to client registrations (HMAC headers).

See also: [Webhooks (dev)](/dev/add-endpoint/webhooks), [Webhooks (integrator)](/integrator/webhooks).

## Doorkeeper protects the API

API clients are Doorkeeper applications. Scopes limit which route families a token may call. Requests carry a Bearer token.

RSwag `describe_api_endpoint` documents client-credential vs resource-owner flows.

See also: [Scopes and permissions](/dev/add-endpoint/scopes-and-permissions), [Client credential flow](/user_documentation/auth/client-credential-flow), [User credential flow](/user_documentation/auth/user-credential-flow).

## OpenAPI: RSwag → swaggerize → openapi-generator → ReDoc

Document endpoints in request specs (RSwag). Do not hand-edit the OpenAPI JSON.

Regenerate with `yarn gen:openapi-spec` → `website/static/openapi.json` (via swaggerize). Generate clients with `yarn gen:node-client` or `bin/gen-node-client`.

The site ReDoc at `/api/` reads that static file. Refresh the docs site after regenerating (`yarn docs:build` or the publish pipeline).

See also: [RSwag](/dev/add-endpoint/rswag), [Generate clients](/dev/add-endpoint/generate-clients), [Command-line tools](/dev/command-line-tools).

## Decidim practice: controller → command → form

Keep controllers thin: authorize, call a command or form, render.

Forms validate params. Commands perform side effects and emit result events. Prefer Decidim domain objects—do not invent parallel business logic in the API layer.

See also: [Controllers](/dev/add-endpoint/controllers), [Async](/dev/add-endpoint/async) (mutations often enqueue commands).

## API design: flat resources, `related`, `meta`

Prefer flat collections with filters over nested trees.

Bad: `/participatory_processes/1/components/meetings`  
Good: `/components/search?filter[participatory_space_id_eq]=1&filter[participatory_space_type_eq]=Decidim::ParticipatoryProcess` (add `filter[manifest_name_eq]=meetings` when you need a component type)

JSON:API-style: attributes on the resource; associations via `relationships` / includes (`related`); non-attribute context in `meta`.

See also: [Space and components](/dev/add-endpoint/space-and-components), [Binding and relations](/dev/add-endpoint/binding-and-relations), [Filtering and pagination](/dev/add-endpoint/filtering-and-pagination), [Serializations](/dev/add-endpoint/serializations).
