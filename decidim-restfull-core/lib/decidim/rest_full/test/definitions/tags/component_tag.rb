# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        COMPONENT = {
          name: "Components",
          description: <<~TXT.strip,
            Participatory-space **components** (`Decidim::Component`): modular features (proposals, blogs, meetings, surveys, …) attached to a space.

            Use **`GET /components/search`** to discover components by manifest, id, participatory space, or name—within the organization resolved from the request host.

            Manifest-specific sub-resources (e.g. `proposal_components`, `blog_components`) expose typed settings for that feature.

            **Extended data**: `GET/PUT /components/{id}/extended_data` (+ `/sync`); filter with `filter[extended_data_cont]` on search. See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
          TXT
          externalDocs: {
            description: "Extended data integrator guide",
            url: "#{Decidim::RestFull.config.docs_url}/integrator/extended-data"
          }
        }.freeze
      end
    end
  end
end
