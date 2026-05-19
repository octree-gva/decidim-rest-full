# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        DRAFT_PROPOSALS = {
          name: "Draft Proposals",
          description: <<~TXT.strip
            Unpublished proposals (`published_at` is `null`) tied to your OAuth application and impersonated participant.

            **One draft per component**: for a given proposals component and user, only a single draft may exist. Creating again returns `400` if a draft is already present.

            **Isolation from the Decidim UI**: drafts created or updated through this API are not editable in the web app, and drafts created in the UI are not visible here.

            **Lifecycle**: create → update (`meta.publishable`) → **publish** (`POST /draft_proposals/:id/publish`, async by default; `…/publish/sync` for inline publication) → the resource becomes a published proposal.

            Requires **impersonation** token (`proposals.draft`); service (client credentials) tokens cannot hold drafts.
          TXT
        }.freeze
      end
    end
  end
end

Decidim::RestFull::Test::OpenApiTagRegistry.register_tag(Decidim::RestFull::Definitions::Tags::DRAFT_PROPOSALS)
