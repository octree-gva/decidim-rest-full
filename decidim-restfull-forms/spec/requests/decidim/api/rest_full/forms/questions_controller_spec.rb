# frozen_string_literal: true

require "swagger_helper"
require "decidim/surveys/test/factories"

RSpec.describe Decidim::Api::RestFull::Forms::QuestionsController do
  path "/questions" do
    get "List questions" do
      tags "Forms"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "listQuestions"
      description "List questions for a questionnaire (filter[questionnaire_id] required)."
      parameter name: "filter[questionnaire_id]", in: :query, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionsController,
        action: :index,
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
        let(:questionnaire) { survey.questionnaire }
        let(:"filter[questionnaire_id]") { questionnaire.id }

        before { host! organization.host }

        response "200", "Questions list" do
          schema type: :object,
                 properties: {
                   data: {
                     type: :array,
                     items: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:question) }
                   },
                   meta: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:forms_locale_meta) }
                 }

          run_test!(example_name: :ok) do |response|
            body = JSON.parse(response.body)
            expect(body["data"]).to be_an(Array)
            expect(body["data"].length).to be >= 1
          end
        end
      end
    end

    post "Create question (async)" do
      tags "Forms"
      consumes "application/json"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "createQuestionsAsync"
      description "Enqueue question creation; poll GET /jobs/:uuid."
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:question_create_body) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionsController,
        action: :create,
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
        let(:questionnaire) { survey.questionnaire }
        let(:body) do
          {
            data: {
              type: "questions",
              attributes: {
                position: 99,
                mandatory: false,
                question_type: "short_answer",
                body: { en: "Async question" }
              },
              relationships: {
                questionnaire: {
                  data: { type: "questionnaires", id: questionnaire.id.to_s }
                }
              }
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

  path "/questions/sync" do
    post "Create question (sync)" do
      tags "Forms"
      consumes "application/json"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "createQuestions"
      description "Create a question inline (201)."
      parameter name: :body, in: :body, required: true,
                schema: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:question_create_body) }

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionsController,
        action: :create_sync,
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
        let(:questionnaire) { survey.questionnaire }
        let(:body) do
          {
            data: {
              type: "questions",
              attributes: {
                position: 99,
                mandatory: false,
                question_type: "short_answer",
                body: { en: "API-created question" }
              },
              relationships: {
                questionnaire: {
                  data: { type: "questionnaires", id: questionnaire.id.to_s }
                }
              }
            }
          }
        end

        before { host! organization.host }

        response "201", "Question created" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:question_item_response)

          run_test!(example_name: :created) do |response|
            parsed = JSON.parse(response.body)
            expect(parsed.dig("data", "attributes", "body", "en")).to eq("API-created question")
          end
        end
      end
    end
  end
end
