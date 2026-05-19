# k6 load tests (hot API operations)

Scenarios mirror the nine **operationId** targets from the capacity plan. Run them **in Docker** via [`docker-compose.perf.yml`](../../docker-compose.perf.yml) so k6 hits the API on the Compose network (`http://rest_full:3000`).

| Scenario file | operationId |
|---------------|-------------|
| `search-components.js` | `searchComponents` |
| `list-blog-posts.js` | `listBlogPosts` |
| `get-blog-post.js` | `getBlogPost` |
| `get-proposal.js` | `getProposal` |
| `cast-proposal-vote.js` | `castProposalVote` / async default |
| `create-role.js` | `createRole` |
| `draft-proposal.js` | `createDraftProposal` |
| `publish-draft-proposal.js` | `publishDraftProposalAsync` |
| `set-user-extended-data.js` | `setUserExtendedData` (`PUT /me/extended_data`) |
| `mixed.js` | weighted mix |
| `smoke.js` | CI smoke (`searchComponents` only) |

## Prerequisites

- Docker Compose (repo root)
- Dummy app + DB set up (`docker compose exec rest_full bin/setup-tests` once)
- OAuth client + fixture ids in `perf/k6/.env` (copy from [`.env.example`](.env.example); never commit `.env`)
- API listening on port **3000** inside `rest_full` (see below)
- For async writes: Redis from the perf overlay + Sidekiq in `rest_full`

## 1. Start the perf stack

From the **repository root**:

```bash
docker compose -f docker-compose.yml -f docker-compose.perf.yml up -d
cp perf/k6/.env.example perf/k6/.env
# Edit perf/k6/.env — secrets and K6_* fixture ids
```

`docker-compose.perf.yml` adds **Redis** (`TRAEFIK_REDIS_URL`) and a **k6** service (`--profile perf`).

## 2. Start the API (and Sidekiq for async scenarios)

The default `rest_full` container does not run Puma. In another terminal:

```bash
# API (dummy app, bound for in-network k6)
docker compose exec rest_full bash -lc '
  cd /home/module/spec/decidim_dummy_app &&
  RAILS_ENV=development bundle exec rails server -b 0.0.0.0 -p 3000
'

# Optional — async jobs (vote, drafts, roles, …)
docker compose exec rest_full bash -lc '
  cd /home/module/spec/decidim_dummy_app &&
  TRAEFIK_REDIS_URL=redis://redis:6379/1 bundle exec sidekiq
'
```

Use `K6_BASE_URL=http://rest_full:3000` in `.env` (default in `.env.example` for Docker). k6 resolves `rest_full` on the Compose network.

To load-test a **staging** host instead, set `K6_BASE_URL=https://your-host` in `.env` and run k6 with only the perf profile (no local API required):

```bash
docker compose -f docker-compose.yml -f docker-compose.perf.yml --profile perf run --rm k6 run scenarios/smoke.js
```

## 3. Run scenarios (Docker)

All commands from **repo root**; `--profile perf` enables the `k6` service.

```bash
# Smoke
docker compose -f docker-compose.yml -f docker-compose.perf.yml --profile perf \
  run --rm k6 run scenarios/smoke.js

# Single hot path
docker compose -f docker-compose.yml -f docker-compose.perf.yml --profile perf \
  run --rm k6 run scenarios/search-components.js

# Weighted mix
docker compose -f docker-compose.yml -f docker-compose.perf.yml --profile perf \
  run --rm k6 run scenarios/mixed.js
```

Override env for one shot (no `.env` edit):

```bash
docker compose -f docker-compose.yml -f docker-compose.perf.yml --profile perf \
  run --rm -e K6_VUS=20 -e K6_DURATION=1m k6 run scenarios/smoke.js
```

Votes default to **async** (`POST /vote_proposals`). Set `K6_VOTE_ASYNC=false` in `.env` to hit `/vote_proposals/sync`.

## Think time

`K6_THINK_MIN` / `K6_THINK_MAX` (seconds) simulate session pacing for large VU counts without implying 100k RPS.

Record results in [`../BASELINE.md`](../BASELINE.md).

## Host k6 (optional)

If you prefer k6 on the host against a published port:

```bash
cd perf/k6
export K6_BASE_URL=http://localhost:3000
set -a && source .env && set +a
k6 run scenarios/smoke.js
```

Install [k6](https://grafana.com/docs/k6/latest/set-up/install-k6/) locally; keep `K6_BASE_URL=http://localhost:3000` in `.env`.
