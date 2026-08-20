# frozen_string_literal: true

module Decidim
  module RestFull
    module Dummy
      # Example external module: Toggle-gated, controller paths registered via Extension.
      # Hit endpoints always raise +ApiException::NotImplemented+ (501).
      class Engine < ::Rails::Engine
        config.root = Dummy::ENGINE_ROOT

        initializer "rest_full.dummy.extension" do
          Decidim::RestFull::Extension.register(:dummy) do |ext|
            ext.toggle_feature gem: "decidim-restfull-dummy"
            ext.controller_paths "dummy", "dummies"
            ext.oauth_scopes :dummy
            ext.permissions(:dummy, "dummy.read", group: :dummy)

            ext.routes do
              Decidim::RestFull::Routing.read_resources(
                self,
                :dummies,
                controller: "dummy/dummies",
                only: [:index, :show]
              )
            end
          end
        end
      end
    end
  end
end
