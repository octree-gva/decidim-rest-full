---
title: Test with Bruno
sidebar_position: 4
---

# Test with Bruno

[Bruno](https://www.usebruno.com/) is a local API client. Import the OpenAPI document as a collection—do not commit a Bruno collection to this repo.

1. **Install Bruno** from the [Bruno site](https://www.usebruno.com/).
2. **Import OpenAPI** as a collection — use the site’s [`/openapi.json`](/openapi.json), or generate locally with `yarn gen:openapi-spec` (writes `website/static/openapi.json`).
3. **Configure** base URL and an OAuth client from [API clients](/user_documentation/client-api-admin). Token steps: [Integrator quickstart](/integrator/quickstart).
4. **Try** a simple authenticated GET against your instance.
5. **Report** problems as [GitLab issues](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-module-rest_full/-/issues).

API docs: [OpenAPI / ReDoc](/api/). Other ways to help: [Ways to contribute](/contribute/ways-to-contribute).
