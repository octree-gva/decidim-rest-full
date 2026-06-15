---
title: Scopes and permissions
sidebar_position: 12
---

## Overview

**OAuth scopes** gate the token (`:proposals`, `:surveys`). **Permissions** gate the action (`ability.authorize!`). Neither is exposed over the public REST API.

## When to use

- You add routes that need a new Doorkeeper scope or system-admin checkbox.
- You document security in RSwag via `describe_api_endpoint`.

## Example

### 1. Register OAuth scopes in the engine

Register in an engine initializer **`before: "rest_full.scopes"`** (see [Boot and extension](./boot-and-extension.md)).

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
Decidim::RestFull::Extension.register(:widgets) do |ext|
  ext.oauth_scopes :widgets   # skip if already in core (:meetings, :debates, …)
end
```

### 2. Register permissions

```ruby
ext.permissions(:widgets, "widgets.read", group: :widgets)
ext.permissions(:widgets, "widgets.manage", group: :widgets)
```

### 3. Add system UI labels

`decidim-restfull-widgets/config/locales/decidim_rest_full_widgets.en.yml`

```yaml
en:
  decidim:
    rest_full:
      permissions:
        widgets:
          widgets.read: Read widgets
          widgets.manage: Manage widgets
```

### 4. Authorize in the controller

`decidim-restfull-widgets/app/controllers/decidim/api/rest_full/widgets/widgets_controller.rb`

```ruby
before_action { doorkeeper_authorize! :widgets }
before_action { ability.authorize! :read, ::Decidim::Widgets::Widget }
```

Forms gem: OAuth scope is **`:surveys`** while permissions use `surveys.*` — copy that split if your Decidim feature already names scopes differently.

### 5. Document security in the request spec

`decidim-restfull-widgets/spec/requests/decidim/api/rest_full/widgets/widgets_controller_show_spec.rb`

```ruby
describe_api_endpoint(
  controller: Decidim::Api::RestFull::Widgets::WidgetsController,
  action: :show,
  security_types: [:credentialFlow],
  scopes: ["widgets"],
  permissions: ["widgets.read"]
) { ... }
```

## Rules

| Rule | Detail |
|------|--------|
| Scope vs permission | Scope on token; permission on user + resource. |
| Forms gem | Engine `:forms`; OAuth scope **`:surveys`**. |
| API clients | [API Clients](../../user_documentation/client-api-admin.md). |
| Core registry | `decidim-restfull-core/lib/decidim/rest_full/core/engine.rb` (`rest_full.permissions`). |
| Boot anchor | Engine initializer `before: "rest_full.scopes"`. |

## Related specs

| Case | Path |
|------|------|
| Roles index | `decidim-restfull-core/spec/requests/.../roles/roles_controller_index_spec.rb` |
| Forms | `decidim-restfull-forms/spec/requests/.../questions_controller_spec.rb` |

## See also

- [Boot and extension](./boot-and-extension.md)
- [Controllers](./controllers.md)
- [RSwag](./rswag.md)
