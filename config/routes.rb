# frozen_string_literal: true

# config/routes.rb
Decidim::RestFull::Engine.routes.draw do
  get "/api/rest/docs", to: "pages#show", as: :documentation_root

  authenticate(:admin) do
    namespace "system" do
      resources :api_clients
    end
  end

  root to: "system/api_clients#index"
end

Decidim::Core::Engine.routes.draw do
  namespace :api do
    namespace :rest_full do
      scope "v#{Decidim::RestFull.major_minor_version}" do
        namespace :spaces do
          resources :spaces, only: [:index, :show, :create, :update, :destroy]
        end
        namespace :system do
          resources :organizations, only: [:index, :show, :create, :update, :destroy]
        end
      end
    end
  end
end
