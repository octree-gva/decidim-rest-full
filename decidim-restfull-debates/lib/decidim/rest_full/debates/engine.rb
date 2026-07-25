# frozen_string_literal: true

module Decidim
  module RestFull
    module Debates
      class Engine < ::Rails::Engine
        config.root = Debates::ENGINE_ROOT

        initializer "rest_full.debates.extension" do

          Decidim::RestFull::Extension.register(:debates) do |ext|
            ext.oauth_scopes :debates
            ext.permissions(:debates, "debates.read", group: :debates)
            ext.open_api_definitions(
              File.join(Debates::ENGINE_ROOT, "lib/decidim/rest_full/debates/test_definitions.rb")
            )
            ext.rswag_specs(File.join(Debates::ENGINE_ROOT, "spec/requests/**/*_spec.rb"))
          end
        end
      end
    end
  end
end
