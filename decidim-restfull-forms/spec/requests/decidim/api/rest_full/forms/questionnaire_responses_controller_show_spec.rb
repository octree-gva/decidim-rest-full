# frozen_string_literal: true

require "swagger_helper"
require "decidim/surveys/test/factories"

RSpec.describe Decidim::Api::RestFull::Forms::QuestionnaireResponsesController do
  path "/questionnaire_responses/{id}" do
    get "Show questionnaire response" do
      tags "Forms"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "getQuestionnaireResponse"
      description "Read a submission bundle (aggregate of Decidim::Forms::Answer rows)."
      parameter name: "id", in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionnaireResponsesController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["surveys"],
        permissions: %w(surveys.answers.read surveys.read)
      ) do
        let!(:organization) { create(:organization, available_locales: %w(en)) }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:surveys_component) do
          create(:surveys_component, participatory_space: participatory_process, published_at: Time.zone.now)
        end
        let!(:survey) { create(:survey, component: surveys_component) }
        let(:questionnaire) { survey.questionnaire }
        let(:question) { questionnaire.questions.not_separator.first }
        let!(:answer) do
          Decidim::Forms::Answer.create!(
            questionnaire:,
            question:,
            body: "Stored answer",
            user: nil
          )
        end
        let(:id) { answer.id }

        before { host! organization.host }

        response "200", "Questionnaire response" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:questionnaire_response_item_response)

          run_test!(example_name: :ok) do |response|
            parsed = JSON.parse(response.body)
            expect(parsed.dig("data", "type")).to eq("questionnaire_response")
            expect(parsed.dig("data", "attributes", "answers")).to be_present
          end
        end
      end
    end
  end
end
