# Performance baseline (Phase 0)

Fill this after running [`perf/k6/`](k6/) against **staging** or the local Docker perf stack (`docker-compose.perf.yml`) that mirrors production (Puma, PgBouncer, Redis, Sidekiq).

Local Docker smoke (repo root):

```bash
docker compose -f docker-compose.yml -f docker-compose.perf.yml --profile perf \
  run --rm k6 run scenarios/smoke.js
```

## Environment

| Field | Value |
|-------|--------|
| Date | _YYYY-MM-DD_ |
| Git ref | _commit sha_ |
| Host URL | _https://…_ |
| Puma | `WEB_CONCURRENCY` × `RAILS_MAX_THREADS` |
| Postgres | version, pool, PgBouncer? |
| Redis / Sidekiq | concurrency, `DECIDIM_REST_QUEUE_NAME` |

## k6 runs

| Scenario | VUs | Duration | p50 ms | p95 ms | p99 ms | 5xx % | 304 % | Notes |
|----------|-----|----------|--------|--------|--------|-------|-------|-------|
| `smoke.js` | 50 | 2m | | | | | | |
| `mixed.js` | | | | | | | | |
| `search-components.js` | | | | | | | | |

## Top slow queries

1. _query / ms / calls_
2. …

## Bottlenecks (before engine fixes)

- _e.g. full-table component search, `collection.ids` on proposal show_

## After optimization (Phase 3)

Repeat the table above and note deltas vs this baseline.
