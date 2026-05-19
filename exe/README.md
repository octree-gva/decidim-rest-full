# `exe/` — command-line entry points

| Script | Purpose |
|--------|---------|
| [`api-client`](./api-client) | Provision OAuth API clients (create, get, grant, revoke). Needs Rails + `config/environment` in CWD. |
| [`decidim-rest_full-client-gem`](./decidim-rest_full-client-gem) | Run `bin/swaggerize` then `bin/gen-node-client` (repo defaults). |
| [`decidim-rest_full-client-gen`](./decidim-rest_full-client-gen) | Generate any OpenAPI Generator client from an existing `openapi.json`. |
| [`decidim-rest_full-openapi`](./decidim-rest_full-openapi) | Check OpenAPI freshness; prompt or run `bin/swaggerize` (~40 min). |

Published documentation: [Command-line tools](https://octree-gva.github.io/decidim-rest-full/dev/command-line-tools) and [Generate clients and OpenAPI](https://octree-gva.github.io/decidim-rest-full/dev/add-endpoint/generate-clients).

Related **`bin/`** scripts (repo root): `swaggerize`, `gen-node-client`, `setup-tests`, `check`.

Gem executable: `bundle exec decidim_restfull_swaggerize` from **`decidim-restfull-dev`** (`decidim-restfull-dev/exe/`).
