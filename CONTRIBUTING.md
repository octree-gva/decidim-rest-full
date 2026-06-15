# Contributing to decidim-restfull

Code covenant for the monorepo. **How-to guides** for adding endpoints live on the [documentation site](website/docs/dev/add-endpoint/) (`website/docs/README.md` describes the site layout).

## License

Contributions are licensed under **AGPL-3.0** ([LICENSE.md](LICENSE.md)). By submitting changes, you agree your work can be distributed under the same license.

## Verification (Docker / CI only)

Per the project playbook, **do not treat host `bundle` / `rspec` / `rubocop` as proof**. Use:

```bash
docker compose up -d
docker compose exec rest_full bash -lc 'cd /home/module && bundle install && ./bin/check'
```

GitLab runs **per-gem RSpec** (see `.gitlab-ci.yml`) then **`rspec:decidim-restfull`** (full suite).

OpenAPI rebuild: `yarn gen:openapi-spec` (docker) or `bundle exec decidim_restfull_swaggerize` from `decidim-restfull-dev`. CLI reference: [Command-line tools](website/docs/dev/command-line-tools.md), [Generate clients and OpenAPI](website/docs/dev/add-endpoint/generate-clients.md).

## Commits and releases

Use **[Conventional Commits](https://www.conventionalcommits.org/)** via `yarn commit` (Commitizen). Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`; optional scope (`proposals`, `openapi`, `integrator`, …). Breaking API changes need a `BREAKING CHANGE:` footer or `feat!` / `fix!` so `standard-version` lists them.

Release maintainer: `yarn release` updates `CHANGELOG.md` and version, then existing `postversion` syncs gemspecs and OpenAPI.

Integrators read [contract changes](website/docs/integrator/contract-changes.md) and root `CHANGELOG.md`.

**CI / local gate:** `./bin/check` runs `bin/lint-spec-harness`, RuboCop (including `Decidim/RestFull/AsyncApiMutation`), ERB lint, Prettier, and all `decidim-restfull-*/spec` via RSpec. Repo-root `spec/` must not contain `*_spec.rb` (harness only).

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

1. **`require "decidim-restfull"`** (metagem) or **`require "decidim-restfull-core"`** plus chosen sibling gems under `decidim-restfull-*`.  
   Loads `lib/decidim/rest_full.rb` (core), then each mounted engine registers through `Extension.register`.

2. **`lib/decidim/rest_full/core/engine.rb`**  
   Global Rails engine (`Decidim.register_global_engine`). `to_prepare`: org/user/system/mailer/Doorkeeper overrides. Initializers: `rest_full.scopes`, `rest_full.menu`, `rest_full.permissions` (core only).

3. **`lib/decidim/rest_full/<feature>/engine.rb`** (`decidim-restfull-proposals`, `blogs`, `meetings`, `debates`, …)  
   Plain `Rails::Engine` mounting `Extension.register`: **proposals/blogs** = full routed surface + permissions; **meetings** = serializers + webhook; **minimal slices** mirror `decidim-restfull-surveys` (`oauth_scopes` only when absent from core’s Doorkeeper merge, `permissions`, OpenAPI barrel).

4. **`decidim-restfull-core/config/routes.rb`**  
   Registers the **core** route block (`RouteRegistry.core_routes_block=`). Feature gems append via `Decidim::RestFull::Extension.register` → `Routes.draw_api_routes`. The core engine initializer **`rest_full.draw_routes`** (after proposals/blogs extensions) calls **`Decidim::RestFull::Routes.draw!`** once on `Decidim::Core::Engine.routes`. Do not call `draw!` from `spec_helper`; the dummy app uses the same boot path as production.

## Where the “magic” is

| Place | What happens | Where to look |
|-------|----------------|---------------|
| **RouteRegistry** | Route blocks are run with `instance_eval` in the Rails router’s scope so that `get`, `resources`, etc. work without a variable. | `lib/decidim/rest_full/core/route_registry.rb` |
| **ApiException::Handler** | Injected into Doorkeeper’s TokensController with `class_eval`; adds `rescue_from` for each exception in `EXCEPTIONS`. | `lib/decidim/rest_full/core/api_exception.rb` |
| **Draft proposal update** | Allowed fields (`title`, `body`) are applied with `form.send(:"#{field_name}=", ...)` so we don’t repeat setters. | `app/controllers/decidim/api/rest_full/draft_proposals/draft_proposals_controller.rb` |
| **OpenAPI tags** | Base tags in `openapi_specs.rb`; feature gems append via `Decidim::RestFull::Test::OpenApiTagRegistry.register_tag`. | `openapi_specs.rb`, optional `test/definitions/tags/*` in feature gems |
| **Spaces / serializers** | Component serializers resolve with `SerializerLookup` (`proposals`, `blogs`, `meetings`, `debates`, … → corresponding `decidim-restfull-*` namespace; unknown → `core`). | `core/serializer_lookup.rb`, adapter gems’ `app/serializers/decidim/api/rest_full/*/`, `components/components_controller.rb` |

## Gem dependencies (Bundler)

Declare **Decidim domain** deps on the matching `decidim-*` gem and **RestFull adapter** deps on `decidim-restfull-core`. Optional participatory spaces (`decidim-assemblies`, `decidim-conferences`, `decidim-initiatives`) are **not** required by core — code guards with `defined?` / `Object.const_defined?`.

| Gem | Depends on |
|-----|------------|
| `decidim-restfull-core` | `decidim-core`, `decidim-admin` |
| `decidim-restfull-proposals` | `decidim-restfull-core`, `decidim-proposals`, `decidim-decidim_awesome` |
| `decidim-restfull-blogs` | `decidim-restfull-core`, `decidim-blogs` |
| `decidim-restfull-meetings` | `decidim-restfull-core`, `decidim-meetings` |
| `decidim-restfull-debates` | `decidim-restfull-core`, `decidim-debates` |
| `decidim-restfull-budgets` | `decidim-restfull-core`, `decidim-budgets` |
| `decidim-restfull-accountabilities` | `decidim-restfull-core`, `decidim-accountability` |
| `decidim-restfull-sortition` | `decidim-restfull-core`, `decidim-sortitions` |
| `decidim-restfull-forms` | `decidim-restfull-core`, `decidim-forms`, `decidim-surveys` (questionnaire specs) |
| `decidim-restfull-surveys` | `decidim-restfull-core`, `decidim-restfull-forms`, `decidim-surveys` |
| `decidim-restfull` (metagem) | all official `decidim-restfull-*` gems above |

Host apps may depend on a **subset** of feature gems (e.g. core + meetings only). Run `decidim-restfull-core/spec/lib/decidim/rest_full/core/optional_feature_gems_spec.rb` after changing guards.

## Engine inventory (release review)

| Engine | Routes | Initializers (typical) | `to_prepare` / notes |
|--------|--------|------------------------|----------------------|
| **Core** | Core routes in `config/routes.rb`; drawn by `Routes.draw!` in `rest_full.draw_routes` | `rest_full.draw_routes`, `rest_full.scopes`, `rest_full.menu`, `rest_full.permissions` | Org/user/system/mailer/Doorkeeper overrides; `Ransackers` |
| **Proposals** | Proposal components + proposals + drafts + votes (`enable_proposals_api`) | `rest_full.proposals.extension` (+ `to_prepare`) | Overrides, webhooks bundle, `ProposalApplicationId`, jobs |
| **Blogs** | Blog components + posts (`enable_blogs_api`) | `rest_full.blogs.extension` | Canonical **small** DSL reference |
| **Meetings** | Serializers + `meetings.read` permission + webhook handler for upcoming reminders | `rest_full.meetings.extension` | Use as **Webhook + DSL** reference |
| **Debates / Surveys / Budgets / Accountabilities / Sortition** | Serializers + `*.read` + optional Doorkeeper scopes; OpenAPI slice | `rest_full.<feature>.extension` | Canonical **minimal** participatory slice without extra CRUD routes |
| **Forms** | Flat questionnaires, questions, answers, submissions (`enable_forms_api`, `surveys` scope) | `rest_full.forms.extension` | JSON Forms projection; `spec/` co-located in gem; OpenAPI under `lib/decidim/rest_full/forms/test/definitions/` |

Shared lib: `Decidim::RestFull::Core::RouteRegistry`, `Configuration`, `PermissionRegistry`, `DefinitionRegistry`, `OpenApiDefinitionPaths`, serializers under each gem’s `app/serializers/decidim/api/rest_full/`. Core ships base test definitions under `decidim-restfull-core/lib/decidim/rest_full/test/definitions/`; each feature adapter adds schemas under its own `lib/decidim/rest_full/test/definitions/` and registers a barrel `lib/decidim/rest_full/<engine>/test_definitions.rb` via `Extension#open_api_definitions` in its engine (same registration model as `ext.rswag_specs`).

## Main directories

- **`lib/decidim/rest_full/`** – Engine, config, route registry, CLI, definition registry, swagger spec path registry, ransackers, `core/overrides`, `proposals/` overrides, test helpers.
- **`app/commands/decidim/rest_full/core/`** – Commands for core domain (`CreateApiClient`, `ImpersonateResourceOwnerFromCredentials`, `SyncronizeUnconfirmedHost`, …).
- **`app/controllers/`** – API and system admin controllers.
- **`app/forms/decidim/rest_full/core/`** – System/API forms (`ApiClientForm`, `ApiPermissions`, `MagicLinkRedirectUrlForm`, `WebhookEventForm`, `WebhookRegistrationForm`, …).
- **`app/models/decidim/rest_full/`** – Domain value objects; **`core/`** for `ApiClient`, `Permission`, `WebhookRegistration`, `MagicToken`, …; in **`decidim-restfull-proposals`**, proposal-specific models such as `Proposals::ProposalApplicationId`.
- **`app/serializers/decidim/api/rest_full/`** — JSON:API serializers: `core/` (shared) plus per-gem namespaces (`proposals/`, `blogs/`, `meetings/`, …). Component serializers resolve via `Core::SerializerLookup`.
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
│   ├── jobs/decidim/rest_full/core/           # core webhook job; proposal webhooks in decidim-restfull-proposals
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

`bin/setup-tests` regenerates `spec/decidim_dummy_app`, runs `decidim_rest_full:install:migrations` (copies migrations from **decidim-restfull-core**), then `db:migrate`. After upgrading the gem, re-run `setup-tests` if new migrations were added (schema changes under `decidim_rest_full_api_jobs`, etc.).

Or only RSpec with the same directories as `.gitlab-ci.yml`:

```bash
docker compose exec rest_full bash -lc 'cd /home/module && unset DATABASE_URL && RAILS_ENV=test bundle exec rspec decidim-restfull-*/spec --format progress'
```

Use `require "spec_helper"` at the top of specs (dummy app harness via decidim/dev). There is no `rails_helper` in this repo.

Request specs use RSwag: they both hit the API and generate OpenAPI snippets. See `spec/swagger_helper.rb` and the site section [Add an endpoint](website/docs/dev/add-endpoint/) (built from `website/`).

**Simple spec examples**: `decidim-restfull-core/spec/requests/decidim/api/rest_full/decidim/rest_full/pages_controller_spec.rb` (one path, one response). `decidim-restfull-core/spec/lib/decidim/rest_full/core/route_registry_spec.rb` (unit test with isolated RouteSet). The repo-root `spec/` directory only holds the dummy app and shared helpers — see `spec/README.md`.

## Naming conventions

- **Decidim vocabulary:** use the same nouns as **decidim-core** and the feature packs (e.g. **Organization** (tenant by `host`), **participatory space**, **Component** with **`manifest_name`**, **Post** for `Decidim::Blogs::Post`, **Proposal** / **ProposalVote** in proposals). Avoid substituting "article", "plugin", or "workspace" for those concepts in user-facing copy and OpenAPI text.

- **Controllers**: `Decidim::Api::RestFull::<Resource>::<Resource>Controller` (e.g. `Proposals::ProposalsController`).
- **Commands**: `Decidim::RestFull::Core::<Action><Subject>` (e.g. `Decidim::RestFull::Core::ImpersonateResourceOwnerFromCredentials`).
- **Forms**: `Decidim::RestFull::<Name>Form` for app-level forms; core models use `Decidim::RestFull::Core::<Name>Form` (e.g. `Decidim::RestFull::Core::WebhookRegistrationForm`).
- **Serializers**: `Decidim::Api::RestFull::<Model>Serializer` (e.g. `ProposalSerializer`).
- **Exceptions**: `Decidim::RestFull::Core::ApiException::<HttpTerm>` (e.g. `ApiException::NotFound`).

## Developer documentation (site)

Procedures live on the doc site under **Add an endpoint** (`website/docs/dev/add-endpoint/`). Structure map: `website/docs/README.md`. Do not duplicate long how-to sections in this file.

## Adding a new API endpoint (checklist)

Start with [Recipe](website/docs/dev/add-endpoint/recipe.md) on the doc site, then:

1. Core routes: `decidim-restfull-core/config/routes.rb`. Feature routes: `Extension.register` → `ext.routes` with `Decidim::RestFull::Routing` — [Routing](website/docs/dev/add-endpoint/routing.md), [Boot and extension](website/docs/dev/add-endpoint/boot-and-extension.md).
2. Controller + operations — [Controllers](website/docs/dev/add-endpoint/controllers.md), [Async](website/docs/dev/add-endpoint/async.md).
3. Request spec + `ext.rswag_specs` — [RSwag](website/docs/dev/add-endpoint/rswag.md).
4. `DefinitionRegistry` schemas in the owning gem — [Test definitions](website/docs/dev/add-endpoint/test-definitions.md).
5. Regenerate OpenAPI — [Generate clients and ReDoc](website/docs/dev/add-endpoint/generate-clients.md).

## External links

- [Rails Guides](https://guides.rubyonrails.org/), [Decidim](https://github.com/decidim/decidim), [Deface](https://github.com/spree/deface) (we use `app/overrides/*.rb`), [RuboCop](https://docs.rubocop.org/), [erb_lint](https://github.com/Shopify/erb-lint), [Prettier](https://prettier.io/).

## Documentation and specs

- **Class-level docs**: Key classes have a short comment at the top (Engine, RouteRegistry, ApiException, DefinitionRegistry, ApplicationController, DoorkeeperConfig, etc.).
- **Tests**: Prefer clear, linear specs over deep nesting. Use `let` for data and one expectation per example when it helps readability. Naming: use the same vocabulary as Decidim (e.g. "organization", "component", "proposal", "form", "command").
- **OpenAPI**: Request specs drive the generated document. **`bin/swaggerize`** loads **`spec/rest_full_swagger_spec_paths.rb`** (gem-local `spec/requests` via `GemSpecPaths`). Shared `/components/search` and `/spaces/...` specs live in **decidim-restfull-core**. Each engine registers **`ext.rswag_specs File.join(ENGINE_ROOT, ...)`**. Regenerate after changing your gem set (`yarn gen:openapi-spec` or `./bin/swaggerize`).
- **Docusaurus site** (`website/`): **Overview**, **Operating the API**, **Developer documentation** → **Add an endpoint** (one topic per page). ReDoc at `/api/` mirrors `website/static/openapi.json`.
