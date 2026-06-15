# Documentation site structure

Published at `/` (see `website/docusaurus.config.ts`). Same rules for every section — no one-off layouts without a maintainer note here.

| Section | Audience | Path |
|---------|----------|------|
| Overview | New deployers | `docs/my-home-doc.md`, `docs/install.md`, `docs/production-mode.md` |
| Operating the API | Integrators, client authors | `docs/user_documentation/` |
| Developer documentation | Module maintainers | `docs/dev/` |
| Add an endpoint | **Gem maintainers** adding RestFull HTTP routes | `docs/dev/add-endpoint/` — see layer stack below |
| Command-line tools | OpenAPI, client gen, `api-client` CLI | `docs/dev/command-line-tools.md` |
| OpenAPI / ReDoc | Integrators | `/api/` (from `static/openapi.json`) |

### Add an endpoint — doc layers (C4-shaped)

| Layer | Pages | Reader gets |
|-------|-------|-------------|
| **Overview** | `recipe.md` | Shape decision → ordered checklist → verify commands |
| **Infrastructure** | `boot-and-extension.md` (+ pointer in `architecture.md`) | Boot order, initializer anchors, append API, scopes merge |
| **Detail** | Remaining topic pages (routing, async, controllers, …) | Single concern per page; same layout on each |

**Conventions**

- File names: `kebab-case.md`
- Front matter: `title`, `sidebar_position` in category folders
- Admonitions: `:::info`, `:::warning`, `:::caution` only when they change behaviour or prevent mistakes
- Every procedure page lists **related specs** under `decidim-restfull-*/spec/`
- Regenerate OpenAPI after request spec changes: `yarn gen:openapi-spec`

Repo contributor covenant and Docker workflow: [CONTRIBUTING.md](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/CONTRIBUTING.md)
