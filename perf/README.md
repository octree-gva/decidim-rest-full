# Performance testing

Load tests live under [`k6/`](k6/). Run them **in Docker** against the dev stack using [`docker-compose.perf.yml`](../docker-compose.perf.yml) (Redis + k6 on the Compose network).

| Doc | Purpose |
|-----|---------|
| [`k6/README.md`](k6/README.md) | Scenarios, env vars, Docker commands |
| [`BASELINE.md`](BASELINE.md) | Record staging / local numbers (Phase 0) |

Quick start:

```bash
# From repo root
docker compose -f docker-compose.yml -f docker-compose.perf.yml up -d
cp perf/k6/.env.example perf/k6/.env   # fill OAuth + fixture ids

# Start API (+ Sidekiq for async scenarios) — see k6/README.md
docker compose -f docker-compose.yml -f docker-compose.perf.yml --profile perf run --rm k6 run scenarios/smoke.js
```
