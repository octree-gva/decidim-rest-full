# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        COMPONENT = {
          name: "Components",
          description: <<~TXT.strip
            Participatory-space **components** (`Decidim::Component`): modular features (proposals, blogs, meetings, surveys, …) attached to a space.

            Use **`GET /components/search`** to discover components by manifest, id, participatory space, or name—within the organization resolved from the request host.

            Manifest-specific sub-resources (e.g. `proposal_components`, `blog_components`) expose typed settings for that feature.
          TXT
        }.freeze
      end
    end
  end
end
