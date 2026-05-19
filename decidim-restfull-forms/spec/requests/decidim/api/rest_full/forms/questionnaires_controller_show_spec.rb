# frozen_string_literal: true

require "swagger_helper"
require "decidim/surveys/test/factories"

RSpec.describe Decidim::Api::RestFull::Forms::QuestionnairesController do
  path "/questionnaires/{id}" do
    get "Questionnaire" do
      tags "Forms"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "getQuestionnaire"
      parameter name: "id", in: :path, schema: { type: :integer }, required: true

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionnairesController,
        action: :show,
        security_types: [:credentialFlow],
        scopes: ["surveys"],
        permissions: %w(surveys.questionnaires.read surveys.read)
      ) do
        let!(:organization) { create(:organization, available_locales: %w(en fr)) }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:surveys_component) do
          create(:surveys_component, participatory_space: participatory_process, published_at: Time.zone.now)
        end
        let!(:survey) { create(:survey, component: surveys_component) }
        let(:id) { survey.questionnaire.id }

        before { host! organization.host }

        response "200", "Questionnaire with schema and ui" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:questionnaire_item_response)

          run_test!(example_name: :ok) do |response|
            body = JSON.parse(response.body)
            expect(body.dig("data", "attributes", "schema")).to be_present
            expect(body.dig("data", "attributes", "ui", "type")).to eq("VerticalLayout")
            expect(body.dig("data", "meta", "locale")).to be_present
            expect(body.dig("data", "links", "submit", "href")).to include("/answers")
          end
        end
      end
    end
  end
end
