---
title: TypeScript SDK
sidebar_position: 8
---

The official TypeScript client is generated from `website/static/openapi.json` into [`contrib/decidim-node-client`](https://github.com/octree-gva/decidim-rest-full/tree/main/contrib/decidim-node-client) and published as **`@octree/decidim-sdk`**.

Regenerate after API changes:

```bash
yarn gen:node-client
```

## Install

```bash
yarn add @octree/decidim-sdk
# or link from the monorepo:
# yarn add file:./contrib/decidim-node-client
```

## Bootstrap

```ts
import { Configuration, OAuthApi, SpacesApi } from "@octree/decidim-sdk";

const host = "https://your-org.example.org";
const apiBase = `${host}/api/rest_full/v0.3`;

const oauth = new OAuthApi(new Configuration({ basePath: apiBase }));

const { data: tokenPayload } = await oauth.createToken({
  oauthGrantParam: {
    grant_type: "client_credentials",
    client_id: process.env.CLIENT_ID!,
    client_secret: process.env.CLIENT_SECRET!,
    scope: "public",
  },
});

const accessToken = tokenPayload.access_token;
const spaces = new SpacesApi(new Configuration({ basePath: apiBase }));

const { data } = await spaces.listAssemblies({
  authorization: `Bearer ${accessToken}`,
  page: 1,
  perPage: 10,
});
```

Protected routes use OpenAPI **`credentialFlowBearer`** / **`resourceOwnerFlowBearer`** security schemes. The generator still expects an `authorization` field on each request object (`Bearer <token>`) until a thin wrapper adds an Axios interceptor.

## API classes (by tag)

| Class | Use for |
|-------|---------|
| `OAuthApi` | `createToken`, `introspectToken` |
| `SpacesApi` | Participatory spaces (`listAssemblies`, `showAssembly`, `searchSpaces`, …) |
| `ComponentsApi` | `searchComponents`, `showProposalComponent`, … |
| `ProposalsApi` | Published proposals, votes (`castProposalVote`, `listProposalVotes`) |
| `DraftProposalsApi` | Draft lifecycle (`getDraftProposal`, `publishDraftProposalAsync`, …) |
| `JobsApi` | Poll async work (`getJob`, `listJobs`) |
| `AttachmentsApi` | List, show, `attachmentsDirectUpload` |
| `FormsApi` | Questionnaires, answers, questions |
| `BlogsApi` | Blog posts (`listBlogPosts`, `createBlogPostAsync`, …) |
| `UsersApi` | `listUsers`, magic links, extended data |
| `OrganizationsApi` | `listOrganizations`, `getOrganization`, `updateOrganization` |
| `OrganizationsExtendedDataApi` | Org extended data hash |
| `RolesApi` | API client roles |

## Naming cheat sheet

| Method | Meaning |
|--------|---------|
| `showAssembly({ id })` | **GET one** assembly (not a list) |
| `listAssemblies()` | List assemblies |
| `castProposalVote()` | Cast a vote on a published proposal |
| `listProposalVotes()` | List vote records |
| `publishDraftProposalAsync()` | Async publish → poll `jobs.getJob` |
| `publishDraftProposal()` | Sync publish |
| `createBlogPostAsync()` | Returns `rest_full_api_job_accepted` (202) |
| `createAnswersAsync()` | Forms async submit (submission request envelope) |

## Async jobs

```ts
import { BlogsApi, JobsApi, Configuration } from "@octree/decidim-sdk";

const blogs = new BlogsApi(config);
const jobs = new JobsApi(config);

const { data: accepted } = await blogs.createBlogPostAsync({
  authorization: `Bearer ${token}`,
  body: { data: { component_id: 1, attributes: { title: { en: "Hi" }, body: { en: "…" } } } },
});

const jobId = accepted.job_id;
const { data: job } = await jobs.getJob({ uuid: jobId });
```

## Browser-only endpoints

Do **not** call `UsersApi.signInWithMagicLink` from server code — it performs an HTTP redirect for end-user browsers. Use `generateMagicLink` and send users the URL instead.

## Filters

Query parameters are camelCase in the SDK (e.g. `filterManifestNameEq`) and map to `filter[manifest_name_eq]` in HTTP.

See also: [Integrator quickstart](./quickstart), [Async and jobs](./async-and-jobs), [Dev: generate clients](../dev/add-endpoint/generate-clients).
