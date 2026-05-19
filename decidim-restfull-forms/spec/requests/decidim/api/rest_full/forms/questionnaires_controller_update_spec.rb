# frozen_string_literal: true

require "swagger_helper"
require "decidim/surveys/test/factories"

RSpec.describe Decidim::Api::RestFull::Forms::QuestionnairesController do
  path "/questionnaires/{id}" do
    put "Update questionnaire metadata (async)" do
      tags "Forms"
      consumes "application/json"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "updateQuestionnaireAsync"
      description "Enqueue questionnaire metadata update (title, description, terms of service). Poll `GET /jobs/:uuid`."
      parameter name: "id", in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:questionnaire_update_body) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionnairesController,
        action: :update,
        security_types: [:credentialFlow],
        scopes: ["surveys"],
        permissions: %w(surveys.questions.manage surveys.read)
      ) do
        let!(:organization) { create(:organization, available_locales: %w(en)) }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:surveys_component) do
          create(:surveys_component, participatory_space: participatory_process, published_at: Time.zone.now)
        end
        let!(:survey) { create(:survey, component: surveys_component) }
        let(:id) { survey.questionnaire.id }
        let(:body) do
          {
            data: {
              type: "questionnaires",
              id: id.to_s,
              attributes: { title: { en: "Async title" } }
            }
          }
        end

        before { host! organization.host }

        response "202", "Job accepted" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_accepted)
          run_test!(example_name: :accepted) do |response|
            expect(response).to have_http_status(:accepted)
            expect(JSON.parse(response.body)).to include("job_id")
          end
        end
      end
    end
  end

  path "/questionnaires/{id}/sync" do
    put "Update questionnaire metadata (sync)" do
      tags "Forms"
      consumes "application/json"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "updateQuestionnaire"
      description "Update questionnaire title, description, or terms of service inline."
      parameter name: "id", in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:questionnaire_update_body) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionnairesController,
        action: :update_sync,
        security_types: [:credentialFlow],
        scopes: ["surveys"],
        permissions: %w(surveys.questions.manage surveys.read)
      ) do
        let!(:organization) { create(:organization, available_locales: %w(en)) }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:surveys_component) do
          create(:surveys_component, participatory_space: participatory_process, published_at: Time.zone.now)
        end
        let!(:survey) { create(:survey, component: surveys_component) }
        let(:id) { survey.questionnaire.id }
        let(:body) do
          {
            data: {
              type: "questionnaires",
              id: id.to_s,
              attributes: {
                title: { en: "Updated questionnaire title" }
              }
            }
          }
        end

        before { host! organization.host }

        response "200", "Questionnaire updated" do
          run_test!(example_name: :ok) do |response|
            parsed = JSON.parse(response.body)
            title = parsed.dig("data", "attributes", "title")
            title_value = title.is_a?(Hash) ? title["en"] : title
            expect(title_value).to eq("Updated questionnaire title")
          end
        end
      end
    end
  end
end
