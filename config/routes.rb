# frozen_string_literal: true

# config/routes.rb

Decidim::Core::Engine.routes.draw do
  authenticate(:admin) do
    namespace "system" do
      resources :api_clients, controller: "/decidim/rest_full/system/api_clients"
      resources :api_permissions, only: [:create], controller: "/decidim/rest_full/system/permissions"
    end
  end

  namespace :api do
    namespace :rest_full do
      scope "v#{Decidim::RestFull.major_minor_version}" do
        post "/oauth/token", to: "/doorkeeper/tokens#create"
        post "/oauth/introspect", to: "/decidim/api/rest_full/introspect#show"
        namespace :system do
          resources :organizations, only: [:index]
          resources :users, only: [:index]
        end
        namespace :public do
          resources :spaces, only: [:index]
          resources :components, only: [:index, :show]
        end
      end
    end
  end
end
