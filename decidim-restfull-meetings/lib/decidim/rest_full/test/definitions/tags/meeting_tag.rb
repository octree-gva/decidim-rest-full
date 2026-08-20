# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        MEETING = {
          name: "Meetings",
          description: <<~TXT.strip,
            Published meetings (`Decidim::Meetings::Meeting`) within visible participatory spaces.

            **Read** (`meetings.read`): list and show meetings; filter by component, space, and `extended_data`.

            **Extended data**: see [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
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

Decidim::RestFull::Test::OpenApiTagRegistry.register_tag(Decidim::RestFull::Definitions::Tags::MEETING)
