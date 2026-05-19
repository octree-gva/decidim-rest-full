# frozen_string_literal: true

module Decidim
  module RestFull
    module Accountabilities
      class Engine < ::Rails::Engine
        config.root = Accountabilities::ENGINE_ROOT

        initializer "rest_full.accountabilities.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_accountabilities_api

          Decidim::RestFull::Extension.register(:accountability) do |ext|
            ext.oauth_scopes :accountability
            ext.permissions(:accountability, "accountability.read", group: :accountability)
            ext.open_api_definitions(
              File.join(Accountabilities::ENGINE_ROOT, "lib/decidim/rest_full/accountabilities/test_definitions.rb")
            )
            ext.rswag_specs(File.join(Accountabilities::ENGINE_ROOT, "spec/requests/**/*_spec.rb"))
          end
        end
      end
    end
  end
end
