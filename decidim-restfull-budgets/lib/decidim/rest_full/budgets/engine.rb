# frozen_string_literal: true

module Decidim
  module RestFull
    module Budgets
      class Engine < ::Rails::Engine
        config.root = Budgets::ENGINE_ROOT

        initializer "rest_full.budgets.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_budgets_api

          Decidim::RestFull::Extension.register(:budgets) do |ext|
            ext.oauth_scopes :budgets
            ext.permissions(:budgets, "budgets.read", group: :budgets)
            ext.open_api_definitions(
              File.join(Budgets::ENGINE_ROOT, "lib/decidim/rest_full/budgets/test_definitions.rb")
            )
            ext.rswag_specs(File.join(Budgets::ENGINE_ROOT, "spec/requests/**/*_spec.rb"))
          end
        end
      end
    end
  end
end
