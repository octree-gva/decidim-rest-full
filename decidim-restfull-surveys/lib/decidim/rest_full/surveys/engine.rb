# frozen_string_literal: true

module Decidim
  module RestFull
    module Surveys
      class Engine < ::Rails::Engine
        config.root = Surveys::ENGINE_ROOT

        initializer "rest_full.surveys.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_surveys_api

          Decidim::RestFull::Extension.register(:surveys) do |ext|
            ext.oauth_scopes :surveys
            ext.permissions(:surveys, "surveys.read", group: :surveys)
            ext.open_api_definitions(
              File.join(Surveys::ENGINE_ROOT, "lib/decidim/rest_full/surveys/test_definitions.rb")
            )
            ext.rswag_specs(File.join(Surveys::ENGINE_ROOT, "spec/requests/**/*_spec.rb"))
          end
        end
      end
    end
  end
end
