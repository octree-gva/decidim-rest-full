# Contributing to decidim-rest_full

This guide helps a new maintainer understand the module with minimal surprises.

## Vocabulary (aligned with Decidim core)

We follow the same terms as [Decidim core](https://github.com/decidim/decidim).

| Term | Meaning in this module |
|------|------------------------|
| **Command** | Single-purpose object that performs a side effect. Lives under `app/commands/`. Has a `call` method; returns a hash with symbols like `:ok`, `:invalid`, `:error`. Use `SomeCommand.call(args) { \|on(:ok) { ... }; on(:invalid) { ... } \}`. |
| **Form** | Object that holds params and validation. Built with `Form.from_params(params).with_context(...)`. Validated with `form.valid?`; errors in `form.errors`. |
| **Controller** | Handles HTTP: params, authorisation, then calls a Command or Form and renders JSON. Thin controllers; business logic in Command/Form. |
| **Ability** | Defines “who can do what” (CanCanCan). We have `Decidim::RestFull::Core::Ability` for API clients (scopes + permissions). |
| **Participatory space** | Decidim concept: process, assembly, conference, etc. We call them “spaces” in the API. |
| **Component** | Feature inside a space (proposals, meetings, blogs, etc.). |
| **Scope** | OAuth scope (e.g. `public`, `proposals`, `system`). Defines which set of endpoints an API client can call. |
| **ROPC** | Resource Owner Password Credentials (OAuth grant). Used for “login as user” or “impersonate” from the API. |

## Entry points (where things get loaded)

1. **`lib/decidim/rest_full.rb`**  
   Top-level require. Order matters: Core lib types → Proposals engine → Blogs engine → Core engine → CLI. Proposals/Blogs must load before `config/routes.rb` runs so `RouteRegistry.draw_api_routes` blocks are registered before `apply!`.

2. **`lib/decidim/rest_full/core/engine.rb`**  
   Global Rails engine (`Decidim.register_global_engine`). `to_prepare`: org/user/system/mailer/Doorkeeper overrides. Initializers: `rest_full.scopes`, `rest_full.menu`, `rest_full.permissions` (core only).

3. **`lib/decidim/rest_full/proposals/engine.rb`** / **`lib/decidim/rest_full/blogs/engine.rb`**  
   Plain `Rails::Engine` (same `config.root` as the gem). Proposals: proposal overrides, webhook subscriptions, proposal permissions, `draw_api_routes` (wrapped in a route `constraints` on `enable_proposals_api`). Blogs: blogs permission, `draw_api_routes` with `enable_blogs_api` constraint.

4. **`config/routes.rb`**  
   Calls `Decidim::RestFull::Core::RouteRegistry.apply!(Decidim::Core::Engine.routes) { ... }` with **core** routes only. Domain engines append via `RouteRegistry.draw_api_routes` in the same `api/rest_full/vX` scope.

## Where the “magic” is

| Place | What happens | Where to look |
|-------|----------------|---------------|
| **RouteRegistry** | Route blocks are run with `instance_eval` in the Rails router’s scope so that `get`, `resources`, etc. work without a variable. | `lib/decidim/rest_full/core/route_registry.rb` |
| **ApiException::Handler** | Injected into Doorkeeper’s TokensController with `class_eval`; adds `rescue_from` for each exception in `EXCEPTIONS`. | `lib/decidim/rest_full/core/api_exception.rb` |
| **Draft proposal update** | Allowed fields (`title`, `body`) are applied with `form.send(:"#{field_name}=", ...)` so we don’t repeat setters. | `app/controllers/decidim/api/rest_full/draft_proposals/draft_proposals_controller.rb` |
| **OpenAPI tags** | Declared in `lib/decidim/rest_full/test/openapi_specs.rb` (rswag metadata) using `Definitions::Tags`. | `lib/decidim/rest_full/test/openapi_specs.rb` |
| **Spaces / serializers** | Component serializers are resolved with `Decidim::Api::RestFull::Core::SerializerLookup` from the manifest name (`proposals` / `blogs` → subfolders; others → `core/`). | `core/serializer_lookup.rb`, `components/components_controller.rb` |

## Engine inventory (release review)

| Engine | Routes | Initializers (typical) | `to_prepare` / notes |
|--------|--------|------------------------|----------------------|
| **Core** | `RouteRegistry.apply!` block in `config/routes.rb` (OAuth, orgs, spaces, component search, roles, users, `/me`) | `rest_full.scopes`, `rest_full.menu`, `rest_full.permissions` | Org/user/system/mailer/Doorkeeper overrides; `Ransackers` |
| **Proposals** | `draw_api_routes`: proposal_components, proposals, draft_proposals, proposal_votes (constraints `enable_proposals_api`) | `rest_full.proposals.webhooks`, `rest_full.proposals.permissions`, `rest_full.proposals.routes` | Proposal + ProposalsController overrides when `Decidim::Proposals` is defined |
| **Blogs** | `draw_api_routes`: blog_components, blogs (constraints `enable_blogs_api`) | `rest_full.blogs.permissions`, `rest_full.blogs.routes` | — |

Shared lib: `Decidim::RestFull::Core::RouteRegistry`, `Configuration`, `PermissionRegistry`, `DefinitionRegistry`, serializers under `app/serializers/decidim/api/rest_full/`, test definitions under `lib/decidim/rest_full/test/definitions/`.

## Main directories

- **`lib/decidim/rest_full/`** – Engine, config, route registry, CLI, definition registry, swagger spec path registry, ransackers, `core/overrides`, `proposals/` overrides, test helpers.
- **`app/commands/decidim/rest_full/core/`** – Commands for core domain (`CreateApiClient`, `ImpersonateResourceOwnerFromCredentials`, `SyncronizeUnconfirmedHost`, …).
- **`app/controllers/`** – API and system admin controllers.
- **`app/forms/decidim/rest_full/core/`** – System/API forms (`ApiClientForm`, `ApiPermissions`, `MagicLinkRedirectUrlForm`, `WebhookEventForm`, `WebhookRegistrationForm`, …).
- **`app/models/decidim/rest_full/`** – Domain value objects; **`core/`** for `ApiClient`, `Permission`, `WebhookRegistration`, `MagicToken`, …; **`proposals/`** for proposal-specific types.
- **`app/serializers/decidim/api/rest_full/`** – JSON:API serializers: `core/` (shared + most component types), `proposals/`, `blogs/`. Dynamic component serializers resolve via `Core::SerializerLookup`.
- **`app/views/`** – System admin (API clients, webhooks).
- **`lib/decidim/rest_full/test/`** – Shared RSpec helpers and OpenAPI definitions used by request specs (live in lib so the gem ships them).

## HTML / view overrides (System admin)

- **Deface:** `app/overrides/system_host_input.rb` — `virtual_path` `decidim/system/organizations/edit` (unconfirmed host UI). When upgrading Decidim, re-check the selector (`replace: "erb[loud]:contains('f.text_field :host')"`) against upstream.
- **Concerns / prepends:** Core UI is also extended via `include` in `lib/decidim/rest_full/core/engine.rb` (`to_prepare`) for forms, commands, and mailers — not only Deface.

## Layout (`tree -L 4`)

From the gem root inside Docker (`docker compose exec rest_full bash -lc 'cd /home/module && tree -L 4 -I "node_modules|vendor|spec/decidim_dummy_app|.git|coverage|tmp|website/node_modules"'`), you should see roughly:

```
.
├── app/
│   ├── commands/decidim/rest_full/core/
│   ├── controllers/decidim/{api/rest_full/,rest_full/system/}
│   ├── forms/decidim/rest_full/core/
│   ├── jobs/decidim/rest_full/{core/,proposals/}
│   ├── models/decidim/rest_full/{core/,proposals/}
│   ├── overrides/          # Deface overrides (*.rb)
│   ├── serializers/decidim/api/rest_full/
│   └── views/decidim/rest_full/
├── bin/                    # setup-tests, swaggerize, check, ci-local, …
├── config/
├── db/migrate/
├── lib/decidim/rest_full/  # engines, core/, proposals/, blogs/, test/
└── spec/
```

## Running tests

**Preferred (matches GitLab `ruby::rspec` default paths):**

```bash
docker compose exec rest_full bash -lc 'cd /home/module && bin/setup-tests && unset DATABASE_URL && RAILS_ENV=test ./bin/check'
```

Or only RSpec with the same directories as `.gitlab-ci.yml`:

```bash
docker compose exec rest_full bash -lc 'cd /home/module && unset DATABASE_URL && RAILS_ENV=test bundle exec rspec spec/commands/ spec/requests/ spec/models/ spec/jobs/ spec/forms/ spec/lib/ spec/decidim/ --format progress'
```

Request specs use RSwag: they both hit the API and generate OpenAPI snippets. See `spec/swagger_helper.rb` and `docs/API_TESTS_AND_OPENAPI.md`.

**Simple spec examples**: `spec/requests/decidim/api/rest_full/pages_controller_spec.rb` (one path, one response). `spec/lib/decidim/rest_full/core/route_registry_spec.rb` (unit test with isolated RouteSet).

## Naming conventions

- **Controllers**: `Decidim::Api::RestFull::<Resource>::<Resource>Controller` (e.g. `Proposals::ProposalsController`).
- **Commands**: `Decidim::RestFull::Core::<Action><Subject>` (e.g. `Decidim::RestFull::Core::ImpersonateResourceOwnerFromCredentials`).
- **Forms**: `Decidim::RestFull::<Name>Form` for app-level forms; core models use `Decidim::RestFull::Core::<Name>Form` (e.g. `Decidim::RestFull::Core::WebhookRegistrationForm`).
- **Serializers**: `Decidim::Api::RestFull::<Model>Serializer` (e.g. `ProposalSerializer`).
- **Exceptions**: `Decidim::RestFull::Core::ApiException::<HttpTerm>` (e.g. `ApiException::NotFound`).

## Adding a new API endpoint

1. Add the route in `config/routes.rb` inside the block passed to `RouteRegistry.apply!`.
2. Add a controller under `app/controllers/decidim/api/rest_full/...` that inherits `Decidim::Api::RestFull::Core::ResourcesController` or follows the same patterns (Doorkeeper auth, Ability, then Command/Form + serializer).
3. Add a request spec under `spec/requests/decidim/api/rest_full/...`; use `describe_api_endpoint` and shared examples from `lib/decidim/rest_full/test/` so the OpenAPI doc is generated.
4. If the response shape is new, register a schema in `DefinitionRegistry` and/or add a definition under `lib/decidim/rest_full/test/definitions/`.

## External links

- [Rails Guides](https://guides.rubyonrails.org/), [Decidim](https://github.com/decidim/decidim), [Deface](https://github.com/spree/deface) (we use `app/overrides/*.rb`), [RuboCop](https://docs.rubocop.org/), [erb_lint](https://github.com/Shopify/erb-lint), [Prettier](https://prettier.io/).

## Documentation and specs

- **Class-level docs**: Key classes have a short comment at the top (Engine, RouteRegistry, ApiException, DefinitionRegistry, ApplicationController, DoorkeeperConfig, etc.).
- **Tests**: Prefer clear, linear specs over deep nesting. Use `let` for data and one expectation per example when it helps readability. Naming: use the same vocabulary as Decidim (e.g. "organization", "component", "proposal", "form", "command").
- **OpenAPI**: Request specs drive the generated spec. Keep tags, operationId, and descriptions in sync with the docs site. Regenerate with `docker compose exec rest_full bash -lc 'cd /home/module && ./bin/swaggerize -o openapi.json'` (or `yarn gen:openapi-spec`).
- **Docusaurus site** (`website/`): optional handoff — align nav with shipped API features; add FAQ entries for Docker, `unset DATABASE_URL`, and OpenAPI generation if contributors keep asking.
