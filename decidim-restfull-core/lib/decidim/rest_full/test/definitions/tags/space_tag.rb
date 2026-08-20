# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        SPACE = {
          name: "Spaces",
          description: <<~TXT.strip,
            Search, list, and fetch participatory spaces (e.g. Assemblies, Participatory Processes).

            **Extended data**: `GET/PUT /spaces/{manifest}/{id}/extended_data` (+ `/sync`); filter with `filter[extended_data_cont]` on search and index. See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
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
