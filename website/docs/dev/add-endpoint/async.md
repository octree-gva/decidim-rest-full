---
title: Async writes and jobs
sidebar_position: 5
---

## Overview

Mutating actions return **202 Accepted**, persist an **`ApiJob`**, enqueue **`ExecuteApiJobJob`**, and expose **`job_id`** + **`poll_url`**. Poll **`GET /api/rest_full/v…/jobs/:uuid`** (no Bearer; UUID is the secret).

Inline work uses **`/sync`** or **`*_sync`** actions (**200/201/204**).

## When to use

- Any new **`create`**, **`update`**, **`destroy`**, **`publish`**, **`vote`** on the public API.
- You register a new command in `ext.api_job` and `ApiJobCommandRunner`.

## Example

### 1. Implement an operations class

`decidim-restfull-widgets/app/services/decidim/rest_full/widgets/widget_operations.rb`

```ruby
module Decidim::RestFull::Widgets
  class WidgetOperations
    def initialize(ctx, params)
      @ctx = ctx
      @params = params
    end

    def create!
      # validate, mutate Decidim models, return JSON-serializable Hash
    end
  end
end
```

:::warning
Do not register a raw `Decidim::Command` in `ApiJobCommandRunner`.
:::

### 2. Register `ext.api_job` in the engine

`decidim-restfull-widgets/lib/decidim/rest_full/widgets/engine.rb`

```ruby
ext.api_job "widgets#create", ->(ctx, p) {
  Widgets::WidgetOperations.new(ctx, p).create!
}
```

### 3. Enqueue from the controller

`decidim-restfull-widgets/app/controllers/decidim/api/rest_full/widgets/widgets_controller.rb`

```ruby
class WidgetsController < Decidim::Api::RestFull::Core::ResourcesController
  include Decidim::Api::RestFull::AsyncApiJobEnqueuing

  def create
    enqueue_rest_full_api_job!("widgets#create") # => 202 + job_id
  end
end
```

### 4. Add a `/sync` route and `*_sync` action

`decidim-restfull-proposals/app/controllers/decidim/api/rest_full/draft_proposals/draft_proposals_controller.rb`

```ruby
def create_sync
  render json: Decidim::RestFull::SyncRunner.call {
    Proposals::DraftProposalsOperations.new(api_execution_context, params).create!
  }
end
```

Route: `post "/sync", action: :create_sync` — see [Routing](./routing.md).

### 5. Document async and sync in RSwag

`decidim-restfull-forms/spec/requests/decidim/api/rest_full/forms/questions_controller_spec.rb`

```ruby
# POST /questions — async
response "202", "Job accepted" do
  run_test! do |response|
    expect(response).to have_http_status(:accepted)
    expect(JSON.parse(response.body)).to include("job_id")
  end
end

# POST /questions/sync — inline (separate path block in the same file)
```

### 6. Run Sidekiq on queue `default`

Set `DECIDIM_REST_QUEUE_NAME` in the host app. Workers must be running for jobs to finish.

## Rules

| Rule | Detail |
|------|--------|
| Default | `create` / `update` / `destroy` / `publish` / `vote` → async unless `*_sync`. |
| `command_key` | Same string in `ext.api_job`, `enqueue_rest_full_api_job!`, and payload. |
| Payload | Stored as JSONB on `decidim_rest_full_api_jobs`; job row id only in Sidekiq args. |
| Size cap | `Decidim::RestFull.config.max_async_api_job_payload_bytes` |
| Forms answers | Async `POST /answers`; poll `/submission_requests/:id` or `/jobs/:id`. |
| Forms authoring | Async default; inline via `/sync` — table below. |
| CI | RuboCop `Decidim/RestFull/AsyncApiMutation` on controllers (excludes `submission_requests`, `controller_helpers`). |
| Exception | `POST /magic_links` returns **201** with token inline (no job). |

## Forms authoring (default async)

| HTTP | Action | `command_key` |
|------|--------|---------------|
| `PUT /questionnaires/:id` | `update` | `forms/questionnaires#update` |
| `POST /questions` | `create` | `forms/questions#create` |
| `PUT /questions/:id` | `update` | `forms/questions#update` |
| `DELETE /questions/:id` | `destroy` | `forms/questions#destroy` |
| `POST /answer_options` | `create` | `forms/answer_options#create` |
| `PUT /answer_options/:id` | `update` | `forms/answer_options#update` |
| `DELETE /answer_options/:id` | `destroy` | `forms/answer_options#destroy` |
| `DELETE /questionnaire_responses/:id` | `destroy` | `forms/questionnaire_responses#destroy` |

Inline: `PUT …/sync`, `POST …/sync`, `DELETE …/sync` → `*_sync` actions. Implementation: `Decidim::RestFull::Forms::AuthoringOperations`.

## Related specs

| Case | Path |
|------|------|
| Jobs poll | `decidim-restfull-core/spec/requests/.../jobs/api_jobs_async_and_conditional_get_spec.rb` |
| Forms answer sync | `decidim-restfull-forms/spec/requests/.../answers_controller_sync_spec.rb` |
| Draft async | `decidim-restfull-proposals/spec/requests/.../draft_proposals_controller_create_spec.rb` |

## See also

- [Routing](./routing.md)
- [Controllers](./controllers.md)
