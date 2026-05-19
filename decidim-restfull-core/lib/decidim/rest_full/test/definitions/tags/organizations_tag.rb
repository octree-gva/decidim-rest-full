# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        ORGANIZATIONS = {
          name: "Organizations",
          description: <<~README
            **Organization** settings (Decidim tenant boundary: primary `host`, secondary hosts, locale defaults, and related configuration).

            One deployment hosts many **Organizations**. Each organization has:

            - `host`: primary domain name
            - `secondary_hosts`: additional hostnames that redirect (301) to `host`

            The active **Organization** is resolved from the request Host header, so different `host` values resolve to that host's organization data.
          README

        }.freeze
      end
    end
  end
end
