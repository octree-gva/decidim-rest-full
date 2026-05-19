# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.3.0]: https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/compare/v0.2.0...v0.3.0
