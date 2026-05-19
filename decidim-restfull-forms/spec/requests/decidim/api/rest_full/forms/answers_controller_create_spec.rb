# frozen_string_literal: true

require "swagger_helper"
require "decidim/surveys/test/factories"

RSpec.describe Decidim::Api::RestFull::Forms::AnswersController do
  path "/answers" do
    post "Submit answers (async)" do
      tags "Forms"
      consumes "application/json"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "createAnswersAsync"
      description "Enqueue answer submission; poll GET /submission_requests/:id (202 Accepted)."
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:questionnaire_answers_create_body) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::AnswersController,
        action: :create,
        security_types: [:credentialFlow],
        scopes: ["surveys"],
        permissions: %w(surveys.answers.submit surveys.read)
      ) do
        let!(:organization) { create(:organization, available_locales: %w(en)) }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:surveys_component) do
          create(:surveys_component, participatory_space: participatory_process, published_at: Time.zone.now)
        end
        let!(:survey) { create(:survey, component: surveys_component) }
        let(:questionnaire) { survey.questionnaire }
        let(:question) { questionnaire.questions.not_separator.first }

        before { host! organization.host }

        let(:body) do
          {
            meta: { locale: "en", anonymous: true, client_ip: "203.0.113.42" },
            data: {
              type: "questionnaire_response",
              attributes: {
                answers: {
                  question.id.to_s => "Async answer"
                }
              },
              relationships: {
                questionnaire: {
                  data: { type: "questionnaires", id: questionnaire.id.to_s }
                }
              }
            }
          }
        end

        response "202", "Submission request accepted" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:submission_request_accepted_response)

          run_test!(example_name: :accepted) do |response|
            expect(response).to have_http_status(:accepted)
            parsed = JSON.parse(response.body)
            expect(parsed.dig("data", "type")).to eq("submission_request")
            expect(parsed.dig("data", "links", "self", "href")).to include("/submission_requests/")
          end
        end
      end
    end
  end
end
