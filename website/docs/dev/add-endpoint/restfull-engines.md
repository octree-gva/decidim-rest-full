---
title: RestFull engines
sidebar_position: 3
---

## Overview

A feature is a **`decidim-restfull-<name>`** gem: Rails engine + `Decidim::RestFull::Extension.register`. The metagem **`decidim-restfull`** only requires siblings; it has no `app/` code.

## When to use

- You add a new Decidim component to the REST API.
- You need OAuth scopes, routes, OpenAPI, or serializer-only registration.

## Example

### 1. Copy an existing gem layout

Use **`decidim-restfull-blogs`** (read-only CRUD) or **`decidim-restfull-forms`** (async + sync) as the template tree under `decidim-restfull-widgets/`.

### 2. Add the gemspec

`decidim-restfull-widgets/decidim-restfull-widgets.gemspec`

```ruby
Gem::Specification.new do |spec|
  spec.name = "decidim-restfull-widgets"
  spec.add_dependency "decidim-restfull-core"
  spec.add_dependency "decidim-widgets" # Decidim feature gem
end
```

### 3. Set ENGINE_ROOT

`decidim-restfull-widgets/lib/decidim-restfull-widgets.rb`

```ruby
module Decidim
  module RestFull
    module Widgets
      ENGINE_ROOT = File.expand_path("..", __dir__)
    end
  end
end
```

### 4. Implement the engine

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
module Decidim
  module RestFull
    module Widgets
      class Engine < ::Rails::Engine
        config.root = Widgets::ENGINE_ROOT

        initializer "rest_full.widgets.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_widgets_api

          Decidim::RestFull::Extension.register(:widgets) do |ext|
            ext.oauth_scopes :widgets
            ext.permissions(:widgets, "widgets.read", group: :widgets)

            ext.open_api_definitions(
              File.join(Widgets::ENGINE_ROOT, "lib/decidim/rest_full/widgets/test_definitions.rb")
            )
            ext.rswag_specs(
              File.join(Widgets::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/widgets/**/*_spec.rb")
            )

            ext.routes do
              constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_widgets_api }) do
                resources :widgets,
                          only: [:index, :show],
                          controller: "/decidim/api/rest_full/widgets/widgets"
              end
            end
          end
        end
      end
    end
  end
end
```

### 5. Add the OpenAPI definitions barrel

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/test_definitions.rb`

```ruby
require_relative "../test/definitions/widget"
```

:::warning
Do **not** add requires to `decidim-restfull-core/lib/decidim/rest_full/test/definitions.rb`.
:::

### 6. Add request specs

`decidim-restfull-widgets/spec/requests/decidim/api/rest_full/widgets/widgets_controller_show_spec.rb` (and siblings).

### 7. Register the gem in the monorepo

- `decidim-restfull/decidim-restfull.gemspec` — add the sibling gem.
- `decidim-restfull-core/lib/decidim/rest_full/core/gem_spec_paths.rb` — add to `GEMS`.
- `decidim-restfull-core/lib/decidim/rest_full/core/configuration.rb` — add `enable_widgets_api`.
- Run `./bin/check`.

## Rules

| Piece | Location |
|-------|----------|
| Engine | `lib/decidim/rest_full/<feature>/engine.rb` |
| Locales | `config/locales/` in the gem (not metagem) |
| Specs | `<gem>/spec/` only |
| Serializer-only adapter | OAuth + permission + OpenAPI schema; no `ext.routes` |
| Feature flag | `Decidim::RestFull::Core::Configuration.enable_<feature>_api` |

## Related specs

| Case | Path |
|------|------|
| Engine boot | `decidim-restfull-surveys/spec/lib/decidim/rest_full/surveys/engine_spec.rb` |
| Disabled routes | `decidim-restfull-core/spec/decidim/rest_full/core/configuration_engine_disabled_routes_spec.rb` |

## See also

- [Architecture](../architecture.md)
- [Routing](./routing.md)
