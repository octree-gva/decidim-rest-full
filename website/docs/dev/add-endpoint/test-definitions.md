---
title: Test definitions (OpenAPI schemas)
sidebar_position: 10
---

## Overview

OpenAPI component schemas live in **`DefinitionRegistry`**, registered from each gem’s `lib/decidim/rest_full/<feature>/test/definitions/`.

## When to use

- You add a new resource type to responses or request bodies.
- You tighten property descriptions for ReDoc.

## Example

### 1. Add a definition file

`decidim-restfull-widgets/lib/decidim/rest_full/test/definitions/widget.rb`

```ruby
Decidim::RestFull::Core::DefinitionRegistry.register_resource(:widget) do
  {
    type: :object,
    title: "Widget",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["widget"] },
      attributes: {
        type: :object,
        properties: {
          title: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
        },
        required: [:created_at, :updated_at, :title],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes]
  }
end
```

### 2. Choose `register_resource` or `register_object`

- **`register_resource(:widget)`** — JSON:API resource body; also registers `:widget_index_response` and `:widget_item_response`.
- **`register_object(:my_payload)`** — arbitrary object (errors, job accepted, OAuth grant, …).

### 3. Use auto-generated response names in RSwag

After `register_resource(:widget)`:

| Symbol | Use in RSwag |
|--------|----------------|
| `:widget` | resource schema |
| `:widget_index_response` | `GET` index |
| `:widget_item_response` | `GET` show / sync body |

### 4. Require files from the barrel

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/test_definitions.rb`

```ruby
require_relative "../test/definitions/widget"
```

### 5. Register the barrel on the engine

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
ext.open_api_definitions(
  File.join(Widgets::ENGINE_ROOT, "lib/decidim/rest_full/widgets/test_definitions.rb")
)
```

Do **not** edit `decidim-restfull-core/lib/decidim/rest_full/test/definitions.rb` for feature schemas.

### 6. Reference schemas in request specs

`decidim-restfull-widgets/spec/requests/decidim/api/rest_full/widgets/widgets_controller_show_spec.rb`

```ruby
response "200", "Widget found" do
  schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:widget_item_response)
  run_test!
end
```

## Common `$ref` symbols (core)

Reuse these in `attributes` instead of redefining `type` / `format`. Loaded from `decidim-restfull-core/lib/decidim/rest_full/test/definitions/` (`shared.rb` + `core.rb`).

```ruby
R = Decidim::RestFull::Core::DefinitionRegistry

created_at: { "$ref" => R.reference(:creation_date) }
updated_at: { "$ref" => R.reference(:edition_date) }
published_at: { "$ref" => R.reference(:publication_date) }
title: { "$ref" => R.reference(:translated_prop) }
```

### Dates and i18n

| Symbol | Use on attribute | OpenAPI |
|--------|------------------|---------|
| `:creation_date` | `created_at` | `string`, `format: date-time` |
| `:edition_date` | `updated_at` | `string`, `format: date-time` |
| `:publication_date` | `published_at` | `string`, `format: date-time` |
| `:translated_prop` | `title`, `body`, `description`, … | locale hash |
| `:locale` | single locale code | string |
| `:locales` | `locales[]` query param | array of `:locale` |
| `:time_zone` | org `time_zone` | string (IANA) |

### Components, spaces, manifests

| Symbol | Use for |
|--------|---------|
| `:component_type` | JSON:API `type` on component resources |
| `:generic_component` | component list/show item |
| `:space_type`, `:space_classes` | space metadata |
| `:space_manifest`, `:component_manifest`, `:resource_manifest` | manifest enums |

### Errors, jobs, auth

| Symbol | Use for |
|--------|---------|
| `:error`, `:error_response` | API errors (`response "4xx"`) |
| `:rest_full_api_job_accepted` | **202** async body |
| `:rest_full_api_job_detail` | `GET /jobs/:uuid` |
| `:rest_full_api_jobs_index_response` | `GET /jobs` index |
| `:client_credential`, `:oauth_grant_param`, … | OAuth token bodies |

### Feature gems (examples)

| Symbol | Gem |
|--------|-----|
| `:forms_validation_error_response`, `:forms_locale_meta` | forms |
| `:draft_proposal`, `:proposal` | proposals |
| `:blog` | blogs |

Grep `register_object` / `register_resource` under `decidim-restfull-*/lib/decidim/rest_full/**/test/definitions/` for the full list.

Link helpers on resource `links`: `DefinitionRegistry#get_action_link`, `#post_action_link`, `#resource_link`.

## Rules

| Rule | Detail |
|------|--------|
| No hand-edited `openapi.json` | Regenerate with `bin/openapi-stale` / `yarn gen:openapi-spec`. |
| Descriptions | Set on resources and non-obvious properties. |
| Forms | `questionnaire`, `questionnaire_response`, `submission_request`, … in forms gem. |

## Related specs

| Case | Path |
|------|------|
| Consumer | Any `*_spec.rb` under `spec/requests/` with `schema "$ref"` |

## See also

- [RSwag](./rswag.md)
- [Generate clients](./generate-clients.md)
