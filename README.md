# Decidim Rest Api
This repository contains a Rails Engine describe a RestAPI for Decidim.
This works is still a work on progress (started end-2024).

## Documentation
The documentation and the API specification are in the [documentation website](https://octree-gva.github.io/decidim-rest-full/).

**New maintainers**: see [CONTRIBUTING.md](CONTRIBUTING.md) for vocabulary (aligned with Decidim core), entry points, where the "magic" lives, and how to run tests.

### Resources supported

- [x] API entry point and metadata
- [x] OAuth (token, introspect; client credentials + resource owner flows)
- [x] Organizations (CRUD, extended data)
- [x] Spaces (search, participatory processes, assemblies)
- [x] Components (search, proposal components, blog components)
- [x] Users
- [x] Current user (`/me`: extended data, magic links)
- [x] Proposals (list, get, draft CRUD, publish)
- [x] Vote on proposals
- [x] Blogs (articles)
- [ ] Taxonomies
- [ ] Meetings
- [ ] Newsletters
- [ ] Official Meetings
- [ ] Menu and navigation
- [ ] Term Customizers

### Webhooks supported

API clients can register webhook URLs in the System Admin (per client); subscriptions are scoped by permissions. Payloads are sent as POST with `X-Webhook-SignatureX-Webhook-Signature` (HMAC-SHA256 of `timestamp.body`) and `X-Webhook-Timestamp`.

- [x] **Proposals**: `draft_proposal_creation.succeeded`, `draft_proposal_update.succeeded`, `proposal_creation.succeeded`, `proposal_update.succeeded` (triggered by Decidim proposal create/update/publish)
- [ ] User lifecycle (`user.created`, `user.updated`) 
- [ ] System organizations (`system.organizations.created|updated|deleted`)

### Scripts

**yarn docs:start**<br />
Start a docusaurus website

**yarn docs:build**<br />
Build the API Redoc and the Docusaurus site. Requires Node 20 (use `nvm use` with the repo’s `.node-version` or `.nvmrc`).

**yarn docs:update**<br />
Generates again the openapi spec, add it to docusaurus, and compile again.

## Engines and configuration

The gem splits into **Core**, **Proposals**, and **Blogs** (see `lib/decidim/rest_full/core/engine.rb`, `proposals/engine.rb`, `blogs/engine.rb`). Only **Core** is registered with `Decidim.register_global_engine`; Proposals/Blogs are plain `Rails::Engine` classes required from `lib/decidim/rest_full.rb` so their initializers register `RouteRegistry.draw_api_routes` before `config/routes.rb` calls `apply!`.

Configure via `Decidim::RestFull.configure` (delegates to `Decidim::RestFull::Core::Configuration`):

- **`enable_proposals_api`** (default `true`): when `false`, proposal-related API routes are not routable (route constraints return 404); proposal overrides and webhook subscriptions are skipped when disabled at boot for webhooks/permissions initializers.
- **`enable_blogs_api`** (default `true`): same pattern for blog routes.

Doorkeeper optional scopes still include `proposals` and `blogs`; behaviour when a feature is off is **404** on those paths (not 403 from Doorkeeper for missing route).

## Route registration (for contributors)

API routes are drawn via `Decidim::RestFull::Core::RouteRegistry`. Core routes live in `config/routes.rb` inside `RouteRegistry.apply!`. Proposals and Blogs append blocks with `RouteRegistry.draw_api_routes { ... }`. Maintainer checklist: [CONTRIBUTING.md](CONTRIBUTING.md) (entry points and engine inventory).

## Development and checks (Docker)

Toolchain versions match the **`rest_full`** Compose image (`octree/decidim-dev:0.29`), not your laptop. Prefer running checks **inside** the container.

```bash
docker compose up -d
docker compose exec rest_full bash -lc 'cd /home/module && bundle install'
docker compose exec rest_full bash -lc 'cd /home/module && bundle exec rubocop .'
docker compose exec rest_full bash -lc 'cd /home/module && bundle exec erblint --lint-all --enable-all-linters'
docker compose exec rest_full bash -lc 'cd /home/module && yarn install --frozen-lockfile && yarn format:check'
```

Generate the dummy app once (`DISABLED_DOCKER_COMPOSE=true` so the Rake task does not restart Compose), then migrate and run specs (unset `DATABASE_URL` so the dummy app’s `config/database.yml` is used):

```bash
docker compose exec rest_full bash -lc 'cd /home/module && DISABLED_DOCKER_COMPOSE=true bundle exec rake test_app'
docker compose exec rest_full bash -lc 'cd /home/module/spec/decidim_dummy_app && unset DATABASE_URL && export DISABLE_SPRING=1 && RAILS_ENV=test bundle exec rails db:create db:migrate'
docker compose exec rest_full bash -lc 'cd /home/module && unset DATABASE_URL && RAILS_ENV=test bundle exec rspec spec/commands/ spec/requests/ spec/models/ spec/jobs/'
```

Or use the CI-style setup script from the repo root (matches GitLab `ruby::rspec`):

```bash
docker compose exec rest_full bash -lc 'cd /home/module && bin/setup-tests'
docker compose exec rest_full bash -lc 'cd /home/module && unset DATABASE_URL && RAILS_ENV=test bundle exec rspec spec/commands/ spec/requests/ spec/models/ spec/jobs/'
```

## Update Versions
> Release a version is up to the maintainer of this repo. 

The main package.json version attribute is dispatch on versionning the ruby engine, allowing to bump the multi-repo with unique version. 

To run these scripts, change your current branch to `main` and do:

Release a patch
```
yarn version --new-version patch --no-git-tag-version
yarn postversion
git add .
git tag v0.0.<yourpatch>
```

Release a minor
```
yarn version --new-version minor --no-git-tag-version
yarn postversion
git add .
git tag $(yarn postversion)
```

## OpenAPI spec and client generation

The OpenAPI document (including **paths**) is produced by **[rswag](https://github.com/rswag/rswag)** request specs, not by a separate exporter. From this repo, run:

```bash
bin/swaggerize -o openapi.json
```

That runs RSpec against `spec/requests/` (and any extra paths you register; see below), then writes `spec/decidim_dummy_app/swagger/v1/swagger.json` to your `-o` file.

**Extra request specs (e.g. another gem in the same app)**  
If a module registers routes and schemas but its RSwag specs live outside this gem, merge those paths into the same run:

- Set `DECIDIM_REST_FULL_SWAGGER_SPEC_PATHS` to comma-separated RSpec path globs, and/or
- Add `spec/rest_full_swagger_spec_paths.rb` at the project root calling `Decidim::RestFull::Core::SwaggerSpecPaths.register(...)` (or `DefinitionRegistry.register_swagger_spec_path(...)`).

**Generate API client**

Requires Node 18+ and `npx` (e.g. `npm install -g npx` or use the project’s node). The module uses `@openapitools/openapi-generator-cli@2`.

```bash
bundle exec decidim-rest_full-client-gen --input openapi.json -o ./client
```

Optional: `--generator typescript-axios` (default), `--check` to only validate the spec and that the generator is available.

## Publish clients
The gem `rswag` generate a valid openapi spec, that then is used to 
generate node clients. We can publish these clients: 

**node-client**<br />
- `yarn gen:node-client`: sync the open-api spec with existing rswag test, and call openapi-generators
- `cd contrib/decidim-node-client && yarn publish`
