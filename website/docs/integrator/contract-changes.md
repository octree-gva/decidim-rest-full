---
sidebar_position: 8
title: Contract changes
description: How API releases are documented in CHANGELOG.md.
---

# Contract changes

API contract version tracks the gem release (`info.version` in OpenAPI).

## CHANGELOG

Release notes are generated with [Conventional Commits](https://www.conventionalcommits.org/) via **Commitizen** + **standard-version** (`yarn release` in the repository).

- **Breaking Changes** section — incompatible HTTP/OpenAPI changes (`BREAKING CHANGE:` footer or `feat!` / `fix!` commits).
- **Features** / **Fixes** — additive or corrective behavior.

Read the root [`CHANGELOG.md`](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/CHANGELOG.md) on GitLab.

## OpenAPI

After each release, [`website/static/openapi.json`](/api) is regenerated. Treat ReDoc as authoritative for paths, parameters, and schemas.

## Contributing

Maintainers: see repository `CONTRIBUTING.md` for commit format and release steps.
