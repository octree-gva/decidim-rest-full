# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Avoid `NameError` on cold boot with `devise_invitable` >= 2.0.13 by preloading
  `ActionMailer::Base` before `to_prepare` (so invitable's `on_load(:action_mailer)`
  does not race `Decidim::ApplicationMailer` definition).

## [0.3.8] - 2026-09-29

### Added

- Named OpenAPI index examples: `ok_empty`, `paginated` / `paginated_last`, `ok_sorted_and_paginated` / `ok_sorted_and_paginated_last`, `filtered_by_*`, `sorted_by_*` / `sorted_by_random` (blogs, proposals, meetings + shared examples).
- Blogs `filtered_by_component` and `ok_sorted_and_paginated(_last)` regression coverage.

### Changed

- Blogs and proposals default order is `published_at` **desc**.
- When `order=rand`, collection `meta.has_more` is always `true` (RANDOM() is unstable across pages).
- OpenAPI `filter_by_*` example names renamed to `filtered_by_*`.

### Fixed

- Blogs index published visibility filter was discarded before `ordered()` (drafts inflated `has_more` on the last page).
- Blogs published_at SQL qualified against `includes(:component)` join ambiguity.

## [0.3.7]

### Added

- Shared collection pagination envelope on every GET index/search: `{ data, meta: { page, per_page, has_more, next, prev } }` via `CollectionPagination` (limit+1, no `COUNT(*)`).
- OpenAPI `collection_meta` / `forms_collection_meta`; all `*_index_response` schemas require `meta`.
- Polymorphic `resource_extended_data` + `HasExtendedData` for organizations, components, spaces, proposals, and meetings (read/write + `filter[extended_data_cont]`).
- `GET /meetings` index/show with extended_data filter.
- Integrator docs: Extended data (`website/docs/integrator/extended-data.md`; linked from OpenAPI via `Decidim::RestFull.config.docs_url`).

### Changed

- **Breaking:** Collection responses always include pagination `meta`. Default `per_page` is **20** (was often 25). Removed `api-pagination` and response `Total` / `Link` pagination headers. No `total_count` / `total_pages` on collections.
- Collection ETags no longer include relation counts; they include `order` / `order_direction`.
- Index sorts use a stable `id` tie-breaker (`ResourcesController#ordered`).
- Organization extended_data storage moves from `organization_extended_data` to polymorphic `resource_extended_data` (migration copies existing rows).
- User `decidim_users.extended_data` / `/me/extended_data` unchanged.
- Hardening: quoted `resource_type` in extended_data ransacker; components search scopes visibility before Ransack; optional sync `extended_data` payload cap (`DECIDIM_REST_MAX_EXTENDED_DATA_PAYLOAD_BYTES`, falls back to async job payload cap).

## [0.3.0] - 2026-05-16

### Added

- Integrator documentation hub (`website/docs/integrator/`) and shell examples (`examples/integrator/`).
- Attachments API: `GET/POST/PUT/DELETE /attachments`, `POST /attachments/direct_upload`.
- Webhook event catalog in OpenAPI **Webhooks** tag.
- `api-client delete` CLI command; non-zero exit codes on CLI errors.
- `decidim_rest_full:seed_integrator_sandbox` rake task for local docker quickstart.
- Commitizen (`yarn commit`) and standard-version (`yarn release`) for generated changelog entries.

### Changed

- OpenAPI `info.description` links to integrator quickstart.
- Contributor docs: PATCH references updated to PUT for sync routes.

[0.3.0]: https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/compare/v0.2.0...v0.3.0
