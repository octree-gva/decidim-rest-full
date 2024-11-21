# frozen_string_literal: true

# config/routes.rb

Decidim::Core::Engine.routes.draw do
  authenticate(:admin) do
    namespace "system" do
      resources :api_clients, controller: "/decidim/rest_full/system/api_clients"
    end
  end

  namespace :api do
    namespace :rest_full do
      scope "v#{Decidim::RestFull.major_minor_version}" do
        namespace :system do
          resources :organizations, only: [:index, :show, :create, :update, :destroy]
        end
        namespace :public do
          resources :spaces, only: [:index]
          resources :components, only: [:index, :show]
        end
      end
    end
  end
end
