# Contributing to decidim-rest_full

This guide helps a new maintainer understand the module with minimal surprises.

## Vocabulary (aligned with Decidim core)

We follow the same terms as [Decidim core](https://github.com/decidim/decidim).

| Term | Meaning in this module |
|------|------------------------|
| **Command** | Single-purpose object that performs a side effect. Lives under `app/commands/`. Has a `call` method; returns a hash with symbols like `:ok`, `:invalid`, `:error`. Use `SomeCommand.call(args) { \|on(:ok) { ... }; on(:invalid) { ... } \}`. |
| **Form** | Object that holds params and validation. Built with `Form.from_params(params).with_context(...)`. Validated with `form.valid?`; errors in `form.errors`. |
| **Controller** | Handles HTTP: params, authorisation, then calls a Command or Form and renders JSON. Thin controllers; business logic in Command/Form. |
| **Ability** | Defines “who can do what” (CanCanCan). We have `Decidim::RestFull::Ability` for API clients (scopes + permissions). |
| **Participatory space** | Decidim concept: process, assembly, conference, etc. We call them “spaces” in the API. |
| **Component** | Feature inside a space (proposals, meetings, blogs, etc.). |
| **Scope** | OAuth scope (e.g. `public`, `proposals`, `system`). Defines which set of endpoints an API client can call. |
| **ROPC** | Resource Owner Password Credentials (OAuth grant). Used for “login as user” or “impersonate” from the API. |

## Entry points (where things get loaded)

1. **`lib/decidim/rest_full.rb`**  
   Top-level require. Order matters: engine, configuration, route_registry, openapi, cli, ransackers, then overrides. Do not reorder without checking `config/routes.rb` and RouteRegistry.

2. **`lib/decidim/rest_full/engine.rb`**  
   Rails engine. `config.to_prepare` includes our overrides into Decidim/Doorkeeper classes. Initializers: `rest_full.webhooks` (events → webhooks), `rest_full.scopes` (Doorkeeper config: grant flows, introspection, ROPC), `rest_full.menu` (system admin menu).

3. **`config/routes.rb`**  
   Calls `Decidim::RestFull::RouteRegistry.apply!(Decidim::Core::Engine.routes) { ... }`. The block is the core API routes; any engine that called `RouteRegistry.draw_api_routes { ... }` earlier gets its block run in the same `api/rest_full/vX` scope.

## Where the “magic” is

| Place | What happens | Where to look |
|-------|----------------|---------------|
| **RouteRegistry** | Route blocks are run with `instance_eval` in the Rails router’s scope so that `get`, `resources`, etc. work without a variable. | `lib/decidim/rest_full/route_registry.rb` |
| **ApiException::Handler** | Injected into Doorkeeper’s TokensController with `class_eval`; adds `rescue_from` for each exception in `EXCEPTIONS`. | `lib/decidim/rest_full/api_exception.rb` |
| **Draft proposal update** | Allowed fields (`title`, `body`) are applied with `form.send(:"#{field_name}=", ...)` so we don’t repeat setters. | `app/controllers/decidim/api/rest_full/draft_proposals/draft_proposals_controller.rb` |
| **OpenAPI tags** | Tag list is built by resolving constants from `Definitions::Tags` (e.g. `API`, `OAUTH`) via `const_get`. | `lib/decidim/rest_full/openapi/export.rb` |
| **Spaces / serializers** | Controllers and serializers use `constantize` on the participatory space type or component manifest name to get the right model/serializer class. | e.g. `app/controllers/decidim/api/rest_full/spaces/spaces_controller.rb`, `app/serializers/.../component_serializer.rb` |

## Main directories

- **`lib/decidim/rest_full/`** – Engine, config, route registry, OpenAPI export, CLI, definition registry, ransackers, overrides, test helpers.
- **`app/commands/`** – Commands (e.g. impersonate user, create API client, sync host).
- **`app/controllers/`** – API and system admin controllers.
- **`app/forms/`** – Form objects (webhooks, API permissions).
- **`app/models/`** – ApiClient, Permission, WebhookRegistration, etc.
- **`app/serializers/`** – JSON:API-style serializers for the REST API.
- **`app/views/`** – System admin (API clients, webhooks).
- **`lib/decidim/rest_full/test/`** – Shared RSpec helpers and OpenAPI definitions used by request specs (live in lib so the gem ships them).

## Running tests

```bash
# Full setup + run (Docker, with DB)
docker compose run --rm rest_full bash -c 'bin/setup-tests && bundle exec rspec spec/requests/ spec/lib/ spec/commands/ spec/models/ spec/jobs/ --format progress'
```

Request specs use RSwag: they both hit the API and generate OpenAPI snippets. See `spec/swagger_helper.rb` and `docs/API_TESTS_AND_OPENAPI.md`.

**Simple spec examples**: `spec/requests/decidim/api/rest_full/pages_controller_spec.rb` (one path, one response). `spec/lib/decidim/rest_full/route_registry_spec.rb` (unit test with isolated RouteSet).

## Naming conventions

- **Controllers**: `Decidim::Api::RestFull::<Resource>::<Resource>Controller` (e.g. `Proposals::ProposalsController`).
- **Commands**: `Decidim::RestFull::<Action><Subject>` (e.g. `ImpersonateResourceOwnerFromCredentials`).
- **Forms**: `Decidim::RestFull::<Name>Form` (e.g. `WebhookRegistrationForm`).
- **Serializers**: `Decidim::Api::RestFull::<Model>Serializer` (e.g. `ProposalSerializer`).
- **Exceptions**: `Decidim::RestFull::ApiException::<HttpTerm>` (e.g. `ApiException::NotFound`).

## Adding a new API endpoint

1. Add the route in `config/routes.rb` inside the block passed to `RouteRegistry.apply!`.
2. Add a controller under `app/controllers/decidim/api/rest_full/...` that uses `ResourcesController` or the same patterns (Doorkeeper auth, Ability, then Command/Form + serializer).
3. Add a request spec under `spec/requests/decidim/api/rest_full/...`; use `describe_api_endpoint` and shared examples from `lib/decidim/rest_full/test/` so the OpenAPI doc is generated.
4. If the response shape is new, register a schema in `DefinitionRegistry` and/or add a definition under `lib/decidim/rest_full/test/definitions/`.

## Documentation and specs

- **Class-level docs**: Key classes have a short comment at the top (Engine, RouteRegistry, ApiException, DefinitionRegistry, ApplicationController, DoorkeeperConfig, etc.).
- **Tests**: Prefer clear, linear specs over deep nesting. Use `let` for data and one expectation per example when it helps readability. Naming: use the same vocabulary as Decidim (e.g. "organization", "component", "proposal", "form", "command").
- **OpenAPI**: Request specs drive the generated spec. Keep tags, operationId, and descriptions in sync with the docs site. (run bin/swaggerize in a docker container to update)
