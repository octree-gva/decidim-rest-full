---
title: Models and migrations
sidebar_position: 15
---

## Overview

RestFull-owned tables live in **`decidim-restfull-core/db/migrate`** (e.g. `decidim_rest_full_api_jobs`). Domain data stays on Decidim models.

## When to use

- You need persistence only the API layer owns (jobs, RestFull metadata).
- You extend Decidim models with concerns or JSON columns on Decidim tables.

## Example

### 1. Prefer existing Decidim models

Use `Decidim::Meetings::Meeting`, `Decidim::Proposals::Proposal`, `Decidim::Forms::Questionnaire`, … — no parallel RestFull tables for domain entities.

### 2. Scope every query to org and ability

```ruby
Widget.where(organization: current_organization)
# plus ability checks in the controller
```

### 3. Add behaviour with `to_prepare` + concern

`decidim-restfull-meetings/lib/decidim/rest_full/meetings/meeting_extended_data.rb`

```ruby
module Decidim::RestFull::Meetings::MeetingExtendedData
  extend ActiveSupport::Concern

  included do
    store_accessor :extended_data, :external_ref, :sync_source
  end
end
```

`decidim-restfull-meetings/lib/decidim/rest_full/meetings/engine.rb`

```ruby
config.to_prepare do
  next unless Decidim::RestFull::Core::Configuration.enable_meetings_api
  Decidim::Meetings::Meeting.include(Decidim::RestFull::Meetings::MeetingExtendedData)
end
```

### 4. Add a migration on the Decidim table (feature gem)

`decidim-restfull-meetings/db/migrate/20260517120000_add_extended_data_to_decidim_meetings_meetings.rb`

```ruby
class AddExtendedDataToDecidimMeetingsMeetings < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_meetings_meetings,
               :extended_data,
               :jsonb,
               null: false,
               default: {}
  end
end
```

Run `bin/setup-tests` or host `rails db:migrate`. Do not edit Decidim core migrations in place.

### 5. Expose the column in the serializer

`decidim-restfull-meetings/app/serializers/decidim/api/rest_full/meetings/meeting_serializer.rb`

```ruby
attribute :extended_data do |meeting|
  meeting.extended_data.presence || {}
end
```

**Users / organizations:** core ships `user_extended_data` and `organization_extended_data` APIs — no extra migration in RestFull. See [Filtering and pagination](./filtering-and-pagination.md).

**RestFull-only tables** (e.g. `decidim_rest_full_api_jobs`): migrations under `decidim-restfull-core/db/migrate/` only.

## Rules

| Rule | Detail |
|------|--------|
| Do not patch Decidim migrations in place | Ship a new engine migration. |
| `has_many` on RestFull namespace | Only on `Decidim::RestFull::` models you own. |
| Extended data (users/orgs) | Core API; columns already on `decidim_users` / `organization_extended_data`. |
| Extended data (other models) | `jsonb :extended_data` in your gem + serializer + permissions. |

## Related specs

| Case | Path |
|------|------|
| ApiJob | `decidim-restfull-core/spec/models/decidim/rest_full/api_job_spec.rb` |
| User extended data | `decidim-restfull-core/spec/requests/.../users/user_extended_data_controller_index_spec.rb` |

## See also

- [Filtering and pagination](./filtering-and-pagination.md)
- [Async](./async.md)
