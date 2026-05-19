# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        PROPOSAL = {
          name: "Proposals",
          description: <<~TXT.strip
            Published proposals (`Decidim::Proposals::Proposal` with `published_at` set) within visible participatory spaces.

            **Read** (`proposals.read`): list and show proposals; filter by component, space, scope, and vote-related facets.

            **Vote proposals** (`proposals.vote`, impersonation): async `POST /vote_proposals` (202 + job poll) or sync `POST /vote_proposals/sync` (slim vote payload; `?include_proposal=true` for full proposal). One vote per author per proposal.

            **Components**: `GET /components/proposal_components` exposes proposals-component settings (votes enabled, limits, phases).

            Draft authoring lives under the **Draft Proposals** tag.
          TXT
        }.freeze
      end
    end
  end
end

Decidim::RestFull::Test::OpenApiTagRegistry.register_tag(Decidim::RestFull::Definitions::Tags::PROPOSAL)
