# frozen_string_literal: true

require "swagger_helper"
require "decidim/surveys/test/factories"

RSpec.describe Decidim::Api::RestFull::Forms::QuestionnairesController do
  path "/questionnaires" do
    get "Questionnaires index" do
      tags "Forms"
      produces "application/json"
      security [{ credentialFlowBearer: ["surveys"] }]
      operationId "listQuestionnaires"
      it_behaves_like "paginated params"

      describe_api_endpoint(
        controller: Decidim::Api::RestFull::Forms::QuestionnairesController,
        action: :index,
        security_types: [:credentialFlow],
        scopes: ["surveys"],
        permissions: %w(surveys.questionnaires.read surveys.read)
      ) do
        let!(:organization) { create(:organization, available_locales: %w(en)) }
        let!(:participatory_process) { create(:participatory_process, organization:) }
        let!(:surveys_component) do
          create(:surveys_component, participatory_space: participatory_process, published_at: Time.zone.now)
        end
        let!(:survey) { create(:survey, component: surveys_component) }

        before { host! organization.host }

        response "200", "Questionnaires list" do
          schema "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:questionnaire_index_response)

          run_test!(example_name: :ok) do |response|
            body = JSON.parse(response.body)
            expect(body["data"]).to be_an(Array)
            expect(body["data"].map { |r| r["id"] }).to include(survey.questionnaire.id.to_s)
          end
        end
      end
    end
  end
end
