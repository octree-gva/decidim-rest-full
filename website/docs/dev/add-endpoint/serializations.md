---
title: Serializations
sidebar_position: 6
---

## Overview

JSON:API-shaped output uses **`jsonapi-serializer`** under `Decidim::Api::RestFull::<Feature>::*Serializer`. Domain services stay in `Decidim::RestFull::<Feature>::`.

## When to use

- You add fields, links, or relationships to API responses.
- You register component schemas for `GET /components/search`.

## Example

### 1. Add a serializer class

`decidim-restfull-widgets/app/serializers/decidim/api/rest_full/widgets/widget_serializer.rb`

```ruby
module Decidim
  module Api
    module RestFull
      module Widgets
        class WidgetSerializer < Decidim::Api::RestFull::Core::ResourceSerializer
          attributes :title, :created_at, :updated_at

          belongs_to :component, serializer: Decidim::Api::RestFull::Core::ComponentSerializer

          meta do |widget, _params|
            { published: widget.published? }
          end
        end
      end
    end
  end
end
```

### 2. Keep namespaces consistent

| Layer | Namespace |
|-------|-----------|
| HTTP (serializer) | `Decidim::Api::RestFull::Widgets::` |
| Domain (operations) | `Decidim::RestFull::Widgets::` |

### 3. Pass `params` from the controller

`decidim-restfull-blogs/app/controllers/decidim/api/rest_full/blogs/blogs_controller.rb`

```ruby
def serializer_params
  {
    locales: available_locales,
    host: current_organization.host,
    act_as:,
    client_id: current_api_client&.uid
  }
end

payload = WidgetSerializer.new(record, params: serializer_params).serializable_hash
```

### 4. Register the OpenAPI resource schema

`decidim-restfull-widgets/lib/decidim/rest_full/test/definitions/widget.rb` — see [Test definitions](./test-definitions.md).

### 5. Map component serializers when needed

Register `SerializerLookup` in the engine if the manifest name does not resolve automatically (adapter gems).

Navigation links on show: see `decidim-restfull-blogs/app/serializers/decidim/api/rest_full/blogs/blog_serializer.rb` (`link :next`, `link :prev`).

## Rules

| Rule | Detail |
|------|--------|
| Hypermedia `links` | Use `DefinitionRegistry` link helpers where applicable. |
| Translatable fields | Follow blogs/proposals patterns for locale in `params`. |
| `rest_enhancement` | Extra attributes/relationships — see [Binding and relations](./binding-and-relations.md). |

## Related specs

| Case | Path |
|------|------|
| Blog post | `decidim-restfull-blogs/spec/requests/.../blogs_controller_show_spec.rb` |
| Questionnaire | `decidim-restfull-forms/spec/requests/.../questionnaires_controller_show_spec.rb` |

## See also

- [Test definitions](./test-definitions.md)
- [Binding and relations](./binding-and-relations.md)
