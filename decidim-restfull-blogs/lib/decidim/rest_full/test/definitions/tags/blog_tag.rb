# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        BLOG = {
          name: "Blogs",
          description: <<~TXT.strip
            Blog posts (`Decidim::Blogs::Post`) on components with the `:blogs` manifest.

            **Visibility** is driven by `published_at`, not a separate published flag:
            - `published_at` is `null` or in the **future** → the post is **not** shown in public index/show (unless you impersonate the author).
            - `published_at` in the **past** → the post is visible to readers with `blogs.read`.

            **Read**: `GET /blogs` and `GET /blogs/:id` (conditional caching on GET).

            **Write** (`blogs.write`): create and update posts (async by default; `POST /blogs/sync`, `PUT /blogs/:id/sync`). **Delete** (`blogs.destroy`): remove a post (`DELETE /blogs/:id`, async; `DELETE /blogs/:id/sync` inline).
          TXT
        }.freeze
      end
    end
  end
end

Decidim::RestFull::Test::OpenApiTagRegistry.register_tag(Decidim::RestFull::Definitions::Tags::BLOG)
