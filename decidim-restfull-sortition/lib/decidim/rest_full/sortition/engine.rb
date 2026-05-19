# frozen_string_literal: true

module Decidim
  module RestFull
    module Sortition
      class Engine < ::Rails::Engine
        config.root = Sortition::ENGINE_ROOT

        initializer "rest_full.sortition.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_sortition_api

          Decidim::RestFull::Extension.register(:sortitions) do |ext|
            ext.oauth_scopes :sortitions
            ext.permissions(:sortitions, "sortitions.read", group: :sortitions)
            ext.open_api_definitions(
              File.join(Sortition::ENGINE_ROOT, "lib/decidim/rest_full/sortition/test_definitions.rb")
            )
            ext.rswag_specs(File.join(Sortition::ENGINE_ROOT, "spec/requests/**/*_spec.rb"))
          end
        end
      end
    end
  end
end
