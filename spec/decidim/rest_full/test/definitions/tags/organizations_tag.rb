# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        ORGANIZATIONS = {
          name: "Organizations",
          description: <<~README
            Organization controls the main configuration of the platform.#{" "}
            As you can host many Decidim in the same platform, organizations allows you to setup:#{" "}

            - host: the domain name used by your decidim
            - secondary_hosts: other domain names, used for redirecting to the correct organizati

            The current organization is guessed from the host of the request, you can thus query the API
            on different hosts to gather organization's related data.
          README

        }.freeze
      end
    end
  end
end
