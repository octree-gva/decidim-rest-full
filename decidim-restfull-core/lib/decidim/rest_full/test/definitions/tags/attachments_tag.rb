# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        ATTACHMENTS = {
          name: "Attachments",
          description: <<~TXT.strip
            Manage **Decidim::Attachment** rows (files linked to proposals, spaces, etc.).

            **Create (mode A):** `POST /attachments` with `multipart/form-data` (`file`, `attached_to_type`, `attached_to_id`, translated `title` / `description`).

            **Create (mode B):** `POST /attachments/direct_upload` → use `signed_id` in `POST /attachments` (`application/json`).

            **Update:** metadata only (`PUT /attachments/{id}`) — no file replacement in v1.

            **List filters:** `filter[attached_to_type]`, `filter[attached_to_id]`, `filter[attachment_collection_id]`, `filter[file_type]` (`image`, `document`, `link`).
          TXT
        }.freeze
      end
    end
  end
end

Decidim::RestFull::Test::OpenApiTagRegistry.register_tag(Decidim::RestFull::Definitions::Tags::ATTACHMENTS)
