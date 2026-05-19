---
title: RSwag (request specs)
sidebar_position: 9
---

## Overview

OpenAPI is generated from **request specs** in each gem. Root `spec/` holds only the dummy app and helpers.

## When to use

- Every new or changed route (including async default and `/sync` variants).
- You need security and permission metadata in the published spec.

## Example

### 1. Add a request spec file

`decidim-restfull-widgets/spec/requests/decidim/api/rest_full/widgets/widgets_controller_show_spec.rb`

### 2. Require the swagger helper

```ruby
require "swagger_helper"
```

### 3. Describe the controller and path

```ruby
RSpec.describe Decidim::Api::RestFull::Widgets::WidgetsController do
  path "/widgets/{id}" do
    get "Show widget" do
      tags "Widgets"
      produces "application/json"
      security [{ credentialFlowBearer: ["widgets"] }]
      operationId "widgetShow"
```

### 4. Wrap examples in `describe_api_endpoint`

```ruby
      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Widgets::WidgetsController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["widgets"],
        permissions: ["widgets.read"]
      ) do
```

### 5. Assert with `run_test!`

```ruby
        let(:id) { widget.id }
        let(:component_id) { component.id }
        let(:space_id) { participatory_process.id }
        let(:space_manifest) { "participatory_processes" }

        response "200", "Widget found" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:widget_item_response)
          run_test! { |ex| expect(JSON.parse(ex.body)["data"]["id"]).to eq(widget.id.to_s) }
        end
      end
```

Async mutation (`decidim-restfull-forms/spec/requests/decidim/api/rest_full/forms/questions_controller_spec.rb`):

```ruby
response "202", "Job accepted" do
  run_test! do |response|
    expect(response).to have_http_status(:accepted)
    expect(JSON.parse(response.body)).to include("job_id")
  end
end
```

### 6. Register spec globs on the engine

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
ext.rswag_specs File.join(Widgets::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/widgets/**/*_spec.rb")
```

### 7. Regenerate OpenAPI

```bash
yarn gen:openapi-spec
# or: bin/openapi-stale --yes  (Docker)
```

## Rules

| Rule | Detail |
|------|--------|
| No spec → no path | Undocumented routes are not in `openapi.json`. |
| Async + sync | Document **202** on default mutation; **200/201** on `*_sync` where applicable. |
| Shared examples | `localized params`, `paginated params`, `describe_api_endpoint` from core test helpers. |
| Paths registry | `spec/rest_full_swagger_spec_paths.rb` + `GemSpecPaths` |

## Related specs

| Case | Path |
|------|------|
| Example | `decidim-restfull-proposals/spec/requests/.../proposals_controller_show_spec.rb` |
| Forms async | `decidim-restfull-forms/spec/requests/.../questions_controller_spec.rb` |

## See also

- [Generate clients](./generate-clients.md)
- [Test definitions](./test-definitions.md)
