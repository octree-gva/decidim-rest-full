# Decidim RestFull API

Rails engines that expose a JSON:API-style REST surface for [Decidim](https://github.com/decidim/decidim), with OAuth scopes, fine-grained permissions, async writes, and OpenAPI driven by tests.

## Documentation

- **Site and ReDoc:** [octree-gva.github.io/decidim-rest-full](https://octree-gva.github.io/decidim-rest-full/) (install, operate the API, contributor guides, live OpenAPI at `/api/`)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md) (code covenant, license, Docker/CI, links to developer docs on the site)

## Monorepo

| Gem | Role |
|-----|------|
| `decidim-restfull` | Metagem — requires core and official feature gems |
| `decidim-restfull-core` | OAuth, system routes, jobs, registries, shared serializers |
| `decidim-restfull-*` | Feature adapters (proposals, blogs, forms, …) |
| `decidim-restfull-dev` | OpenAPI swaggerize helper |

Layout and extension DSL: [Architecture](website/docs/dev/architecture.md) on the doc site.

**E2e:** `extended_data` clear-at-path returns `{}` (not 404) via `Decidim::RestFull::Core::ExtendedDataAtPath`. Consumed by [NCA e2e](../../nca/contrib/e2e/README.md) and [chat-platform e2e](../../chat-platform/e2e/README.md).

## Local checks (Docker)

```bash
docker compose up -d
docker compose exec rest_full bash -lc 'cd /home/module && ./bin/check'
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for `bin/setup-tests` and per-gem RSpec.

## License

AGPL-3.0 — see [LICENSE.md](LICENSE.md).
