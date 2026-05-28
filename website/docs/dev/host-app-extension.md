---
title: Host app extensions
sidebar_position: 15
description: Add RestFull routes and OpenAPI from a Decidim host application (no feature gem).
---

## Overview

Most endpoints live in **`decidim-restfull-*` gems**. You can also register routes from the **host Decidim app** (tenant-specific APIs, chatbot bridges, legacy paths) with the same **`Extension.register`** DSL.

Use this when the API is tied to one deployment and does not belong in a reusable gem.

Reference implementation: **NCA chatbot** (`config/initializers/decidim_restfull_nca_chatbot.rb` in the NCA host app).

## When to use

- One-off or tenant-specific HTTP surface on the RestFull mount (`/api/rest_full/v0.3/…`).
- Controllers stay in the host app (`app/controllers/decidim/…`).
- You still want OpenAPI, RSwag, and a TypeScript client in CI.

Prefer a **`decidim-restfull-<feature>` gem** when the API is reusable across deployments. See [RestFull engines](./add-endpoint/restfull-engines.md).

## Procedure

### 1. Register the extension at boot

`config/initializers/my_restfull_extension.rb`:

```ruby
Rails.application.config.after_initialize do
  require "decidim/rest_full"
  next unless defined?(Decidim::RestFull::Extension)

  Decidim::RestFull::Extension.register(:my_feature) do |ext|
    ext.open_api_definitions Rails.root.join("lib/decidim/my_app/rest_full/test_definitions.rb").to_s
    ext.rswag_specs Rails.root.join("spec/requests/decidim/api/rest_full/my_app/**/*_spec.rb").to_s

    ext.routes do
      get "my_resource/:id", to: "/decidim/my_app/my_resources#show"
    end
  end

  Decidim::RestFull::Routes.draw! unless Decidim::RestFull::Routes.routes_drawn?
end
```

`require "decidim/rest_full"` is required: the gem is not fully loaded until Bundler resolves the host app.

### 2. Controller outside `Decidim::Api::RestFull`

Host controllers use an app-specific namespace (e.g. `Decidim::MyApp::Api::MyResourcesController`) with a concern for OAuth, not `Decidim::Api::RestFull::ApplicationController` (Zeitwerk conflict with `decidim-api`).

Include RestFull OAuth helpers from your app (`Decidim::MyApp::Api::RestFullController` or similar).

Routes still use **absolute controller paths**: `to: "/decidim/my_app/my_resources#show"`.

### 3. OpenAPI definitions and RSwag specs

Same rules as feature gems:

- [Test definitions](./add-endpoint/test-definitions.md) — register schemas in `DefinitionRegistry`.
- [RSwag](./add-endpoint/rswag.md) — request specs under `spec/requests/decidim/api/rest_full/<app>/`.
- `describe_api_endpoint` requires `permissions: []` (or explicit abilities) and FactoryBot in `swagger_helper.rb`.

### 4. Generate merged OpenAPI

Host apps cannot run every RestFull gem spec in-process (Zeitwerk / `Decidim::Api::RestFull` loading). Merge instead:

1. Start from **`decidim-restfull/openapi.json`** (full RestFull contract).
2. Run **host RSwag specs only** to append your paths.

Example (NCA):

```bash
docker compose exec decidim bash -lc 'bin/gen-openapi'
# → openapi/nca-openapi.json
```

Host script pattern:

```bash
cp "$DECIDIM_RESTFULL_PATH/openapi.json" swagger/v1/swagger.json
GENERATE_OPENAPI=1 bundle exec rspec spec/requests/decidim/api/rest_full/my_app/**/*_spec.rb \
  --format Rswag::Specs::SwaggerFormatter
mv swagger/v1/swagger.json openapi/my-openapi.json
```

### 5. TypeScript client

```bash
docker compose exec decidim bash -lc 'bin/gen-typescript-client'
# → contrib/my-decidim-client
```

Publish to your GitLab npm registry on `main` / tags (see host app CI). Consumer install:

```bash
npm install @<namespace>/my-decidim-sdk
```

See [Generate clients](./add-endpoint/generate-clients.md) and [TypeScript SDK](../integrator/typescript-sdk.md).

### 6. Swagger helper extras (host app)

`spec/swagger_helper.rb` typically needs:

```ruby
require "decidim/rest_full/test/on_api_endpoint_methods"
require "decidim/rest_full/test/global_context"
RSpec.configure { |c| c.include FactoryBot::Syntax::Methods }
```

Load RestFull OAuth models if Zeitwerk does not pick them up (`Decidim::RestFull::Core::ApiClient`, etc.).

Include `Decidim::RestFull::OrganizationClientIdsOverride` on `Decidim::Organization` when factories create `api_client` records.

## Rules

| Rule | Detail |
|------|--------|
| Boot order | `after_initialize` + `require "decidim/rest_full"` before `Extension.register`. |
| Draw routes once | `Decidim::RestFull::Routes.draw!` after all extensions register. |
| Controller path | Absolute `/decidim/...` in `ext.routes`; avoid `Decidim::Api::RestFull::*` in host app. |
| OpenAPI merge | Base spec from monorepo + host RSwag only; do not re-run all gem specs in the host. |
| Legacy URLs | Keep old paths in `config/routes.rb` until consumers migrate; document both in OpenAPI if needed. |
| `is_protected: false` | RSwag records `security: []` and can corrupt OAuth `scope` enums; host `gen-openapi` scripts should restore grant schemas from the base spec after merge. |
| CI | Regenerate OpenAPI + client on release; publish npm package from committed spec. |

## See also

- [Add an endpoint](./add-endpoint/restfull-engines.md) — feature gem layout
- [Routing](./add-endpoint/routing.md)
- [Generate clients and OpenAPI](./add-endpoint/generate-clients.md)
- [Command-line tools](./command-line-tools.md)
