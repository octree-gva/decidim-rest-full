# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      class Engine < ::Rails::Engine
        config.root = Forms::ENGINE_ROOT

        initializer "rest_full.forms.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_forms_api

          Decidim::RestFull::Extension.register(:forms) do |ext|
            ext.oauth_scopes :surveys
            ext.permissions(:surveys, "surveys.questionnaires.read", group: :surveys)
            ext.permissions(:surveys, "surveys.questions.manage", group: :surveys)
            ext.permissions(:surveys, "surveys.answers.read", group: :surveys)
            ext.permissions(:surveys, "surveys.answers.submit", group: :surveys)
            ext.permissions(:surveys, "surveys.answers.destroy", group: :surveys)

            ext.api_job "forms/answers#create", ->(ctx, p) { Forms::AnswersOperations.new(ctx, p).create! }
            ext.api_job "forms/questionnaires#update", ->(ctx, p) { Forms::AuthoringOperations.new(ctx, p).update_questionnaire! }
            ext.api_job "forms/questions#create", ->(ctx, p) { Forms::AuthoringOperations.new(ctx, p).create_question! }
            ext.api_job "forms/questions#update", ->(ctx, p) { Forms::AuthoringOperations.new(ctx, p).update_question! }
            ext.api_job "forms/questions#destroy", ->(ctx, p) { Forms::AuthoringOperations.new(ctx, p).destroy_question! }
            ext.api_job "forms/answer_options#create", ->(ctx, p) { Forms::AuthoringOperations.new(ctx, p).create_answer_option! }
            ext.api_job "forms/answer_options#update", ->(ctx, p) { Forms::AuthoringOperations.new(ctx, p).update_answer_option! }
            ext.api_job "forms/answer_options#destroy", ->(ctx, p) { Forms::AuthoringOperations.new(ctx, p).destroy_answer_option! }
            ext.api_job "forms/questionnaire_responses#destroy", lambda { |ctx, p|
              Forms::AuthoringOperations.new(ctx, p).destroy_questionnaire_response!
            }

            ext.open_api_definitions(
              File.join(Forms::ENGINE_ROOT, "lib/decidim/rest_full/forms/test_definitions.rb")
            )

            ext.rswag_specs(
              File.join(Forms::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/forms/**/*_spec.rb")
            )

            ext.routes do
              constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_forms_api }) do
                Decidim::RestFull::Routing.async_resources(
                  self,
                  :questionnaires,
                  controller: "forms/questionnaires",
                  only: [:index, :show, :update]
                )

                Decidim::RestFull::Routing.async_resources(
                  self,
                  :questions,
                  controller: "forms/questions",
                  only: [:index, :show, :create, :update, :destroy]
                )

                Decidim::RestFull::Routing.async_resources(
                  self,
                  :answer_options,
                  controller: "forms/answer_options",
                  only: [:index, :create, :update, :destroy]
                )

                Decidim::RestFull::Routing.async_resources(
                  self,
                  :answers,
                  controller: "forms/answers",
                  only: [:index, :create]
                )

                resources :questionnaire_responses, only: [:show, :destroy],
                                                    controller: "/decidim/api/rest_full/forms/questionnaire_responses" do
                  member do
                    put "/", action: :update_forbidden
                    delete "sync", action: :destroy_sync
                  end
                end

                Decidim::RestFull::Routing.read_resources(
                  self,
                  :submission_requests,
                  controller: "forms/submission_requests",
                  only: [:show]
                )
              end
            end
          end
        end
      end
    end
  end
end
