# Integrator examples

Shell scripts for the [integrator quickstart](https://octree-gva.github.io/decidim-rest-full/integrator/quickstart).

## Environment

| Variable | Description |
|----------|-------------|
| `HOST` | Decidim host (no scheme), e.g. `localhost` |
| `CLIENT_ID` | OAuth client id |
| `CLIENT_SECRET` | OAuth client secret |
| `TOKEN` | Bearer token (set by `01-token.sh`) |
| `COMPONENT_ID` | From `02-search-components.sh` |
| `DRAFT_ID` | From `03-draft-create-sync.sh` |

## Scripts

1. `01-token.sh` — client credentials token
2. `02-search-components.sh` — `GET /components/search`
3. `03-draft-create-sync.sh` — `POST /draft_proposals/sync`
4. `04-draft-publish-sync.sh` — `POST …/publish/sync`
5. `05-vote-proposal.sh` — optional vote (needs user token + `proposals.vote`)

Requires `curl` and `jq`.
