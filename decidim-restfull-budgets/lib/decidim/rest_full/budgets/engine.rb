# frozen_string_literal: true

module Decidim
  module RestFull
    module Budgets
      class Engine < ::Rails::Engine
        config.root = Budgets::ENGINE_ROOT

        initializer "rest_full.budgets.extension" do
          Decidim::RestFull::Extension.register(:budgets) do |ext|
            ext.toggle_feature gem: "decidim-restfull-budgets"
            ext.controller_paths "budgets"
            ext.oauth_scopes :budgets
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
