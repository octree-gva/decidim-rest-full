# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      module Definitions
        module Tags
          FORMS = {
            name: "Forms",
            description: <<~TXT.strip
              Survey and questionnaire authoring backed by Decidim::Forms.

              **Questionnaire** (`Decidim::Forms::Questionnaire`) is the container: title, description, and terms of service. It belongs to a survey resource (e.g. `Decidim::Surveys::Survey`) via `questionnaire_for`.

              **Questions** (`Decidim::Forms::Question`) define rows in the questionnaire (`question_type`, `body`, `mandatory`, …). **Answer options** (`Decidim::Forms::AnswerOption`) belong to choice-style questions.

              **Participant flow**: answers are submitted as a bundle (`POST /answers` → `submission_requests/:id` for validation state). **Questionnaire responses** (`GET /questionnaire_responses/:id`) expose a read model of stored answers; admins can delete a response bundle.

              **Authoring** (credential token, `surveys.questions.manage`): mutate questionnaires, questions, and answer options. Default writes are **async** (`HTTP 202` + `GET /jobs/:uuid`); use `…/sync` routes for inline `200`/`201`.

              **Listing**: `GET /questionnaires` returns a JSON Forms projection for rendering; `GET /questions` and `GET /answers` require `filter[questionnaire_id]`.
            TXT
          }.freeze
        end
      end
    end
  end
end

Decidim::RestFull::Test::OpenApiTagRegistry.register_tag(Decidim::RestFull::Forms::Definitions::Tags::FORMS)
