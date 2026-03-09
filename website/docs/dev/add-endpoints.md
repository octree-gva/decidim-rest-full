---
sidebar_position: 2
title: Extend the API with custom endpoints
---

This page explains how to plug your own endpoints or modules into `decidim-rest_full`, and how this fits in the overall system.

## High‑level architecture

- **Clients and tokens**: System admins create API clients and permissions from the Decidim backoffice. See [Client API admin](../user_documentation/client-api-admin.md) and the auth docs for the [client credential flow](../user_documentation/auth/client-credential-flow.md) and the [user credential flow](../user_documentation/auth/user-credential-flow.md).
- **OAuth gateway**: All requests hit `/oauth/token` or `/oauth/introspect` first (Doorkeeper), then go through `Decidim::Api::RestFull::ApplicationController`, which exposes helpers like `current_organization`, `current_user`, `act_as` and `ability`.
- **Scopes and permissions**: Tokens carry **scopes** (e.g. `proposals`, `blogs`, `system`) and **permissions** (e.g. `proposals.read`, `oauth.impersonate`). `Decidim::RestFull::Ability` turns those into `can?`/`authorize!` rules.
- **Routes and controllers**: Core routes are drawn via `Decidim::RestFull::RouteRegistry.apply!` (see `config/routes.rb`). External modules register additional routes by calling `RouteRegistry.draw_api_routes { ... }`. Controllers live under `app/controllers/decidim/api/rest_full/<domain>/`.
- **OpenAPI and docs**: Request specs (rswag) + `DefinitionRegistry` build the OpenAPI document, which powers the `/api` documentation page and client generation (`exe/decidim-rest_full-openapi`, `exe/decidim-rest_full-client-gen`). See the refactoring plan in `docs/REFACTORING_PLAN.md` for more internals.

Once you understand this flow, adding a new endpoint is “just” wiring a route, a controller, optional serializers, permissions and OpenAPI definitions.

## Where to hook your own module

You normally extend the API from **your own gem/module** (or from the host app) by:

- Registering routes with `Decidim::RestFull::RouteRegistry.draw_api_routes`.
- Implementing controllers under `app/controllers/decidim/api/rest_full/<your_domain>/`.
- Optionally adding serializers under `app/serializers/decidim/api/rest_full/`.
- Optionally registering OpenAPI schemas with `Decidim::RestFull::DefinitionRegistry`.

You **do not** need to change the core gem to expose extra endpoints.

## Example: add a `groups` CRUD endpoint

This is a minimal, end‑to‑end example showing how a module could expose a `groups` API on top of `Decidim::UserGroup` (or your own `Group` model).

### 1. Decide scopes and permissions

Pick a scope (e.g. `groups`) and permissions:

- `groups.read` – list and show groups.
- `groups.write` – create, update and delete groups.

You would:

- Seed those permissions alongside your module (e.g. in a Rails task or seed).
- Register them in the permission registry so they appear in the System UI:

```ruby
# in your engine initializer
Decidim::RestFull::PermissionRegistry.register(:groups, "groups.read", group: :groups)
Decidim::RestFull::PermissionRegistry.register(:groups, "groups.write", group: :groups)
```

Then assign them to API clients via the existing system UI. See [Client API admin](../user_documentation/client-api-admin.md) for how clients and permissions are exposed to admins.

### 2. Register routes with RouteRegistry

In your module’s engine initializer (e.g. `lib/decidim/my_module/engine.rb`):

```ruby
Decidim::RestFull::RouteRegistry.draw_api_routes do
  resources :groups,
            only: [:index, :show, :create, :update, :destroy],
            controller: "/decidim/api/rest_full/groups/groups"
end
```

This will mount your endpoints under:

- `GET /api/rest_full/vX/groups`
- `GET /api/rest_full/vX/groups/:id`
- `POST /api/rest_full/vX/groups`
- `PUT/PATCH /api/rest_full/vX/groups/:id`
- `DELETE /api/rest_full/vX/groups/:id`

…inside the same versioned scope as the rest of the API.

:::caution Duplicate resources
`RouteRegistry` does not prevent you from registering the same resource or path twice. If two engines register conflicting routes, Rails will use the last one that was drawn. Make sure your path (`/groups` in this example) is not already used by core or another module.
:::

### 3. Implement the controller

Create `app/controllers/decidim/api/rest_full/groups/groups_controller.rb` in your module:

```ruby
module Decidim
  module Api
    module RestFull
      module Groups
        class GroupsController < ResourcesController
          before_action { doorkeeper_authorize! :groups }
          before_action { ability.authorize! :read, ::Decidim::UserGroup }, only: [:index, :show]
          before_action { ability.authorize! :manage, ::Decidim::UserGroup }, except: [:index, :show]

          def index
            render json: GroupSerializer.new(
              paginate(collection),
              params: serializer_params
            ).serializable_hash
          end

          def show
            render json: GroupSerializer.new(
              find_group!,
              params: serializer_params
            ).serializable_hash
          end

          def create
            group = build_group
            group.save!
            render json: GroupSerializer.new(group, params: serializer_params).serializable_hash,
                   status: :created
          end

          def update
            group = find_group!
            group.update!(group_params)
            render json: GroupSerializer.new(group, params: serializer_params).serializable_hash
          end

          def destroy
            find_group!.destroy!
            head :no_content
          end

          private

          def collection
            ::Decidim::UserGroup.where(organization: current_organization)
          end

          def find_group!
            collection.find(params.require(:id))
          end

          def build_group
            collection.new(group_params.merge(organization: current_organization))
          end

          def group_params
            params.require(:data).permit(:name, :document_number, :phone)
          end

          def serializer_params
            { locales: available_locales, host: current_organization.host }
          end
        end
      end
    end
  end
end
```

This follows the same pattern as the built‑in resources controllers:

- Uses `doorkeeper_authorize! :groups` (scope).
- Uses `ability` (permissions derived from the token) to gate actions.
- Uses `current_organization` and `available_locales` from the base API controller.

### 4. Add a serializer (optional but recommended)

Create `app/serializers/decidim/api/rest_full/group_serializer.rb`:

```ruby
module Decidim
  module Api
    module RestFull
      class GroupSerializer < ApplicationSerializer
        attributes :name, :document_number, :phone

        attribute :created_at do |group|
          group.created_at.iso8601
        end

        attribute :updated_at do |group|
          group.updated_at.iso8601
        end
      end
    end
  end
end
```

You can also define relationships and links, following the existing serializers under `app/serializers/decidim/api/rest_full/`.

### 5. Register OpenAPI schemas (optional)

To expose your `group` resource in the OpenAPI document, define a schema under your module or contribute to `DefinitionRegistry`:

```ruby
# lib/decidim/rest_full/test/definitions/group.rb (or your own gem)
Decidim::RestFull::DefinitionRegistry.register_resource(:group) do
  {
    type: :object,
    title: "Group",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["group"] },
      attributes: {
        type: :object,
        properties: {
          name: { type: :string, description: "Group name" },
          document_number: { type: :string, description: "Legal document number (optional)" },
          phone: { type: :string, description: "Contact phone (optional)" },
          created_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:edition_date) }
        },
        required: [:name, :created_at, :updated_at],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes]
  }.freeze
end
```

Then use rswag request specs to document the paths, following the existing specs under `spec/requests/decidim/api/rest_full/`.

### 5.1 OpenAPI helper methods reference

`Decidim::RestFull::DefinitionRegistry` exposes a small DSL to help you build schemas consistently:

- **Registering schemas**
  - `register_object(:key) { ... }` – register a reusable object schema.
  - `register_resource(:key) { ... }` – register a JSON:API-style resource (id/type/attributes/meta/links/relationships).
  - `extends_object(:key, :parent) { |schema| ... }` – extend an existing object schema.
  - `register_response_for(:key)` – register a standard response wrapper for a resource or object.
- **Referencing schemas**
  - `reference(:key)` – returns a JSON Pointer (`#/components/schemas/...`) for another schema.
  - `schema_for(:key)` – returns a schema hash registered under another key (used for `:locales`, etc.).
- **Links and relationships**
  - `resource_link` – standard JSON:API `link` object (`self`, `related`, etc.).
  - `get_action_link` – link object for GET actions (used by magic-link redirect definitions).
  - `belongs_to("schema_key", title: ...)` – build a `belongs_to` relationship wrapper.
  - `belongs_to_relation(ref_hash, title: ...)` – same, starting from an existing `$ref`.
  - `has_many("schema_key", ..., title: ...)` – build a `has_many` relationship wrapper.
  - `has_many_relation(ref_hash, title: ...)` – same, starting from an existing `$ref`.

You can see concrete usage under `lib/decidim/rest_full/test/definitions/*.rb` (e.g. `proposal.rb`, `space.rb`, `component.rb`).

### 6. Wire permissions and test

1. Ensure your module seeds the `groups` scope and the `groups.read` / `groups.write` permissions.
2. From the Decidim system admin, grant those permissions to an API client.
3. Request a token for the `groups` scope.
4. Call your new endpoints with `Authorization: Bearer <token>`.

For advanced topics (versioning, multi‑tenant behaviour, host safety, extended data), see:

- [How does it work?](../index.md)
- [Safe `host` update](./update-hosts.md)

