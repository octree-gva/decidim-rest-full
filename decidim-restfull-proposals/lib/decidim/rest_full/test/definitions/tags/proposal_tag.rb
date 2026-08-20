# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        PROPOSAL = {
          name: "Proposals",
          description: <<~TXT.strip,
            Published proposals (`Decidim::Proposals::Proposal` with `published_at` set) within visible participatory spaces.

            **Read** (`proposals.read`): list and show proposals; filter by component, space, scope, and vote-related facets.

            **Vote proposals** (`proposals.vote`, impersonation): async `POST /vote_proposals` (202 + job poll) or sync `POST /vote_proposals/sync` (slim vote payload; `?include_proposal=true` for full proposal). One vote per author per proposal.

            **Components**: `GET /components/proposal_components` exposes proposals-component settings (votes enabled, limits, phases).

            **Extended data**: `GET/PUT /proposals/{id}/extended_data` (+ `/sync`); filter with `filter[extended_data_cont]` on index. See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).

            Draft authoring lives under the **Draft Proposals** tag.
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

Decidim::RestFull::Test::OpenApiTagRegistry.register_tag(Decidim::RestFull::Definitions::Tags::PROPOSAL)
