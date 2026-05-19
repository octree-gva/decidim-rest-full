# @octree/decidim-sdk

TypeScript **Axios** client for the [Decidim REST Full API](https://octree-gva.github.io/decidim-rest-full/), generated from `website/static/openapi.json`.

## Install

```bash
yarn add @octree/decidim-sdk
```

## Usage

```ts
import { Configuration, OAuthApi, SpacesApi } from "@octree/decidim-sdk";

const config = new Configuration({
  basePath: "https://your-org.example.org/api/rest_full/v0.3",
});

const oauth = new OAuthApi(config);
const { data: token } = await oauth.createToken({
  oauthGrantParam: {
    grant_type: "client_credentials",
    client_id: process.env.CLIENT_ID!,
    client_secret: process.env.CLIENT_SECRET!,
    scope: "public",
  },
});

const spaces = new SpacesApi(config);
await spaces.listAssemblies({
  authorization: `Bearer ${token.access_token}`,
});
```

## Regenerate

From the repo root:

```bash
yarn gen:node-client
```

## Documentation

- [TypeScript SDK guide](https://octree-gva.github.io/decidim-rest-full/integrator/typescript-sdk)
- [Integrator quickstart](https://octree-gva.github.io/decidim-rest-full/integrator/quickstart)

## License

AGPL-3.0-only
