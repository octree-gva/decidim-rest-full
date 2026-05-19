# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        JOBS = {
          name: "Jobs",
          description: <<~TXT.strip
            Durable records for **asynchronous API writes** (`decidim_rest_full_api_jobs`).

            When a mutating route returns **HTTP 202**, the body includes `job_id` (UUID). Poll **`GET /jobs/{id}`** without a Bearer token—the UUID is the capability—or list jobs with the **same OAuth application and resource owner** via **`GET /jobs`** (Bearer required).

            Filter the index with `filter[command_key]` (job name, e.g. `draft_proposals#create`) and `filter[status]` (`pending`, `processing`, `completed`, `failed`). Delete a job with **`DELETE /jobs/{id}`** (same OAuth context as the list).
          TXT
        }.freeze
      end
    end
  end
end
