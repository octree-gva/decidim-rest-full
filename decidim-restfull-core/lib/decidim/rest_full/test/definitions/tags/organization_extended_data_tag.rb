# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        ORGANIZATION_EXTENDED_DATA = {
          name: "Organizations Extended Data",
          description: <<~README
            Read organization `extended_data` and merge updates under a dot-path via sync (`PUT /organizations/{id}/extended_data/sync`). Supports recursive merge, dot paths (use `.` for the root), path creation, and clearing keys by setting them to null or empty—see the operation description for full examples. Requires `system` scopes as documented on each operation.
          README

        }.freeze
      end
    end
  end
end
