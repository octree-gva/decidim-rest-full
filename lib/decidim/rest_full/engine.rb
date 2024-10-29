# frozen_string_literal: true

module Decidim
  module RestFull
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::RestFull

      routes do
        get "/api/rest/docs", to: "pages#show", as: :documentation_root
      end

      initializer "rest_full.mount_routes" do
        Decidim::Core::Engine.routes do
          mount Decidim::RestFull::Engine, at: "/", as: "rest_full"
          mount Decidim::RestFull::Root, at: "/api/rest"
        end
      end
    end
  end
end
