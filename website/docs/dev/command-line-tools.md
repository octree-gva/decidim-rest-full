---
sidebar_position: 5
title: Command-line tools
description: Binaries and scripts under exe/, bin/, and decidim-restfull-dev for OpenAPI, clients, and API client provisioning.
---

## Overview

The monorepo ships **shell entry points** at the repository root. They fall into three groups: **OpenAPI generation**, **HTTP client generation**, and **API client provisioning** (OAuth applications in System).

| Path | Role |
|------|------|
| `bin/swaggerize` | Build `openapi.json` from RSwag request specs |
| `bin/gen-node-client` | Generate and build the bundled TypeScript client |
| `exe/decidim-rest_full-client-gem` | `swaggerize` + `gen-node-client` in one command |
| `exe/decidim-rest_full-client-gen` | Generate a client from an existing spec (any OpenAPI Generator language) |
| `decidim-restfull-dev` gem → `decidim_restfull_swaggerize` | Thin wrapper around `bin/swaggerize` |
| `exe/api-client` | CLI: create / get / grant / revoke API clients (needs a loaded Rails app) |

Host Decidim apps can register extensions from an initializer (no feature gem). See [Host app extensions](./host-app-extension.md).

Repo-local pointer: [exe/README.md](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/exe/README.md).

:::info
Run Ruby and OpenAPI tasks **inside Docker** when developing this module (`docker compose exec rest_full bash -lc 'cd /home/module && …'`). See [CONTRIBUTING.md](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/CONTRIBUTING.md).
:::

---

## OpenAPI: `bin/swaggerize`

Produces **`openapi.json`** by running RSwag against all gem-local request specs.

**Prerequisites**

1. `bin/setup-tests` (dummy app + DB migrated).
2. `spec/rest_full_swagger_spec_paths.rb` registers globs via `GemSpecPaths` (every `decidim-restfull-*/spec/requests/**/*_spec.rb`).

**Usage**

```bash
bin/swaggerize --out website/static/openapi.json
bin/swaggerize --quiet -o /tmp/my-openapi.json
```

**What it does**

1. Resolves RSpec paths (`Decidim::RestFull::Core::SwaggerSpecPaths`).
2. Runs `rspec … --format Rswag::Specs::SwaggerFormatter` with `SWAGGER_DRY_RUN=0`.
3. Moves `spec/decidim_dummy_app/swagger/v1/swagger.json` to `--out`.

**Extra spec paths**

- `DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS` — comma-separated globs.
- Or register in Ruby: `Decidim::RestFull::Core::SwaggerSpecPaths.register("my/glob/**/*_spec.rb")`.

**Yarn shortcut (Docker Compose)**

```bash
yarn gen:openapi-spec
```

Equivalent to `bin/swaggerize -o website/static/openapi.json` in the `rest_full` service.

**Gem wrapper**

```bash
bundle exec decidim_restfull_swaggerize --out ./openapi.json
```

From the **`decidim-restfull-dev`** gem (`decidim-restfull-dev/exe/decidim_restfull_swaggerize` → repo `bin/swaggerize`).

See [Generate clients and OpenAPI](./add-endpoint/generate-clients.md) and [RSwag](./add-endpoint/rswag.md).

---

## TypeScript client: `bin/gen-node-client`

Generates **`contrib/decidim-node-client`** (TypeScript Axios) from an existing spec.

**Usage**

```bash
bin/gen-node-client --validate --input website/static/openapi.json
```

| Option | Meaning |
|--------|---------|
| `--input FILE` | OpenAPI JSON (default `./openapi.json`) |
| `--validate` / `-v` | Run `openapi-generator-cli validate` first |
| `--quiet` / `-q` | Less logging |
| `--axios VERSION` | Axios version passed to generator (default `1.7.7`) |

**What it does**

1. Optional validation via `@openapitools/openapi-generator-cli` (version pinned in repo `openapitools.json`, currently **7.9.0**).
2. `openapi-generator-cli generate -g typescript-axios` → `contrib/decidim-node-client`.
3. `yarn format` + `yarn build` inside that package.

**Yarn shortcut**

```bash
yarn gen:node-client
```

Requires `website/static/openapi.json` to exist (run `yarn gen:openapi-spec` first).

---

## One-shot: `exe/decidim-rest_full-client-gem`

Runs **swaggerize** then **gen-node-client** with defaults for this repo.

```bash
./exe/decidim-rest_full-client-gem
./exe/decidim-rest_full-client-gem --spec-out /tmp/openapi.json --client-out /tmp/client --verbose
```

| Option | Default |
|--------|---------|
| `--spec-out FILE` | `website/static/openapi.json` |
| `--client-out DIR` | *(ignored today; `gen-node-client` always writes `contrib/decidim-node-client`)* |
| `--verbose` | Off (`VERBOSE=1` also enables command echo) |

:::warning
`--client-out` is accepted but **`bin/gen-node-client` output path is fixed** to `contrib/decidim-node-client`. Use `decidim-rest_full-client-gen` for a custom output directory.
:::

---

## Any language: `exe/decidim-rest_full-client-gen`

Wrapper around **OpenAPI Generator** via `npx @openapitools/openapi-generator-cli@2` (same family as `bin/gen-node-client`).

**Validate only**

```bash
./exe/decidim-rest_full-client-gen --check --input website/static/openapi.json
```

**Generate**

```bash
./exe/decidim-rest_full-client-gen \
  --input website/static/openapi.json \
  --output /tmp/my-php-client \
  --generator php
```

| Option | Meaning |
|--------|---------|
| `--input FILE` | OpenAPI 3 document (required) |
| `-o`, `--output DIR` | Output directory (required for generate) |
| `--generator NAME` | OpenAPI Generator name (default `typescript-axios`) |
| `--check` | Validate spec + confirm CLI is available |

For `typescript-axios`, extra properties match the repo defaults (`useSingleRequestParameter`, `paramNaming=camelCase`, `axiosVersion`).

**Common generators**

| Language | `--generator` | Notes |
|----------|---------------|--------|
| TypeScript (Axios) | `typescript-axios` | Same as `bin/gen-node-client` |
| TypeScript (fetch) | `typescript-fetch` | Alternative TS client |
| Python | `python` | [OpenAPI Generator python docs](https://openapi-generator.tech/docs/generators/python) |
| PHP | `php` | [OpenAPI Generator php docs](https://openapi-generator.tech/docs/generators/php) |

Full list: [https://openapi-generator.tech/docs/generators](https://openapi-generator.tech/docs/generators).

You can also call the CLI directly (same version as the repo):

```bash
yarn openapi-generator-cli validate -i website/static/openapi.json
yarn openapi-generator-cli generate -i website/static/openapi.json -o ./out/python -g python
```

---

## API client provisioning: `exe/api-client`

Manages **OAuth API clients** (Doorkeeper applications + RestFull permissions) from the shell. Implementation: `decidim-restfull-core/lib/decidim/rest_full/cli/`.

:::warning
Requires a **booted Rails app** with Decidim and RestFull loaded. The script calls `require …/config/environment` relative to **current working directory** (host app or `spec/decidim_dummy_app` after `setup-tests`).

```bash
cd spec/decidim_dummy_app
BUNDLE_GEMFILE=../../Gemfile bundle exec ../../exe/api-client create --help
```

For day-to-day admin, use the [System UI](../user_documentation/client-api-admin.md) instead.
:::

| Command | Purpose |
|---------|---------|
| `create` | New client with `--scope`, optional `--permission`, `--organization-id` |
| `get` | Show one client (`--id`) or list all |
| `grant` | Add permission to existing client |
| `revoke` | Remove permission |

Set `DISABLE_REST_FULL_BIN=true` to disable the CLI in restricted deployments.

Full option reference: [API client CLI](./api-client-cli.md).

---

## Related yarn scripts

| Script | Action |
|--------|--------|
| `yarn gen:openapi-spec` | `bin/swaggerize` → `website/static/openapi.json` |
| `yarn gen:node-client` | `bin/gen-node-client --validate` |
| `yarn docs:compile_re_doc` | Validate spec + build static `api-docs.html` |
| `yarn docs:build` | ReDoc HTML + Docusaurus site |
| `yarn postcommit` | setup-tests, format, openapi, node client, ReDoc |
| `bin/openapi-stale` / `exe/decidim-rest_full-openapi` | Check staleness; prompt before full swaggerize |
| `yarn gen:openapi-spec:check` | Exit 1 if `openapi.json` is stale (CI) |

---

## See also

- [Generate clients and OpenAPI](./add-endpoint/generate-clients.md) — end-to-end workflow for your own `openapi.json` and third-party clients
- [RSwag](./add-endpoint/rswag.md) — specs that feed the spec file
- [OpenAPI / ReDoc on the site](/api/) — published contract
