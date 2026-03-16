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
Build the API Redoc and the Docusaurus site. Requires Node 20 (use `nvm use` with the repo’s `.nvmrc`).

**yarn docs:update**<br />
Generates again the openapi spec, add it to docusaurus, and compile again.

## Route registration (for contributors)

API routes are drawn via `Decidim::RestFull::RouteRegistry`. Domain engines (e.g. Proposals, Blogs) register route blocks with `RouteRegistry.draw_api_routes { ... }`. **Load order**: require domain engines in `lib/decidim/rest_full.rb` **before** the core engine so their initializers run before `config/routes.rb` calls `RouteRegistry.apply!`.

## Run tests
You can run tests on the same image used by the pipeline, to be confident to push: 
```
docker compose  -f docker-compose.yml bundle exec rspec spec/commands/ spec/requests/ spec/models/ spec/jobs/ --format progress --format RspecJunitFormatter --out rspec.xml
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

## OpenAPI export and client generation (from your app)

From your Decidim app (with `decidim-rest_full` in the bundle), you can export a base OpenAPI spec and generate API clients without touching the module internals.

**Export base OpenAPI (info, servers, tags, components.schemas only; no paths)**

```bash
bundle exec decidim-rest_full-openapi --host https://your-decidim.org --locales ca,en,es -o base.json
```

Defaults: `--host` from `ENV['HOST']`, `--locales` from `ENV['DECIDIM_AVAILABLE_LOCALES']`. Omit `-o` to print JSON to stdout.

**Full openapi.json (with paths from Rswag)**  
Paths come from the module’s Rswag request specs. Two-step flow:

1. Run the binstub: `bundle exec decidim-rest_full-openapi --host https://your-decidim.org -o base.json`
2. From the module repo, run `bin/swaggerize -o paths.json` (or your CI that runs Rswag and writes the spec)
3. Merge `paths` from the Rswag output into `base.json` (e.g. script or manual merge)

Optionally, use the module’s `yarn gen:openapi-spec` if you have the module checked out and Docker.

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
