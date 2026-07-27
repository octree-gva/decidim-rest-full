---
title: First contribution
sidebar_position: 5
---

# First contribution

New contributors who write **code**—welcome. This page is for **code** Merge Requests (Ruby, and docs-in-repo that need CI). Others start at [Ways to contribute](/contribute/ways-to-contribute).

Work is tracked as [issues on GitLab](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/issues).

:::tip
First time here? Pick a small or welcoming issue, leave a short comment that you are taking it, then open a Merge Request against that issue.
:::

Conduct and license: repository [CONTRIBUTING.md](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/blob/main/CONTRIBUTING.md). Published docs: [octree-gva.github.io/decidim-rest-full](https://octree-gva.github.io/decidim-rest-full/).

## Two ways to open a Merge Request

You can change the project in either of these ways (they are not mutually exclusive):

1. **GitLab web UI** — edit in the browser, propose a Merge Request.
2. **Git CLI** — clone your fork, branch, push, open a Merge Request.

Both end the same way: a Merge Request on the upstream project for review.

## Using the GitLab web UI

1. **Fork** the [project](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full) into your GitLab namespace.
2. On your fork, create a **feature branch** from an up-to-date `main`. Never commit on `main`.
3. **Edit** the files you need, commit on that branch.
4. Open a **Merge Request** from your branch into upstream `main`. Link the related issue.
5. Address review comments; when merged, **delete** the feature branch on your fork.

If you are fixing a reported issue, comment on the issue so others know it is taken.

## Using Git on the command line

1. Fork the project on GitLab (same as above).
2. Clone **your fork**, then add the upstream remote:

```bash
git remote add upstream https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full.git
```

3. Sync `main` from upstream (`fetch` + merge or rebase), then create a feature branch.
4. Commit your work on that branch (see [Commits](#commits)).
5. Push the branch to your fork and open a **Merge Request** into upstream `main`.
6. After merge, delete the local and remote feature branch; keep `main` aligned with upstream.

## Verify before opening a Merge Request

Before you open a Merge Request, run the same checks as CI: Compose service `rest_full`, then `./bin/check` from the module root inside the container. On a fresh clone, run `bin/setup-tests` once first (it builds the gitignored dummy app—do not commit that tree).

```bash
docker compose up -d
docker compose exec rest_full bash -lc 'cd /home/module && ./bin/check'
```

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/). Prefer `yarn commit` (Commitizen) so the message format stays consistent for changelog and releases.

## What to change

Do not invent architecture here—follow the existing docs:

| Topic | Page |
|-------|------|
| How the API is built | [Core concepts](/contribute/core-concepts) |
| How the project and CI are structured | [Architecture](/dev/architecture) |
| Adding an HTTP endpoint | [Recipe](/dev/add-endpoint/recipe) |
| How to install | [Installation](/install) |

## Further reading

- [Decidim contributing guide](https://docs.decidim.org/en/develop/develop/guide_getting_started.html) — community norms for Decidim modules
- [Rails Guides](https://guides.rubyonrails.org/) — optional background for Rails engines
