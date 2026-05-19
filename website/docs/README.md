# Documentation site structure

Published at `/` (see `website/docusaurus.config.ts`). Same rules for every section — no one-off layouts without a maintainer note here.

| Section | Audience | Path |
|---------|----------|------|
| Overview | New deployers | `docs/my-home-doc.md`, `docs/install.md`, `docs/production-mode.md` |
| Operating the API | Integrators, client authors | `docs/user_documentation/` |
| Developer documentation | Module maintainers | `docs/dev/` |
| Add an endpoint | Contributors adding routes | `docs/dev/add-endpoint/` (14 pages; same layout each) |
| Command-line tools | OpenAPI, client gen, `api-client` CLI | `docs/dev/command-line-tools.md` |
| OpenAPI / ReDoc | Integrators | `/api/` (from `static/openapi.json`) |

**Conventions**

- File names: `kebab-case.md`
- Front matter: `title`, `sidebar_position` in category folders
- Admonitions: `:::info`, `:::warning`, `:::caution` only when they change behaviour or prevent mistakes
- Every procedure page lists **related specs** under `decidim-restfull-*/spec/`
- Regenerate OpenAPI after request spec changes: `yarn gen:openapi-spec`

Repo contributor covenant and Docker workflow: [CONTRIBUTING.md](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-rest_full/-/blob/main/CONTRIBUTING.md)
