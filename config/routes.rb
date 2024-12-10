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
        post "/oauth/introspect", to: "/doorkeeper/tokens#introspect"

        namespace :system do
          resources :organizations, only: [:index]
          resources :users, only: [:index]
        end
        namespace :public do
          resources :spaces, only: [:index]
          resources :components, only: [:index, :show]

          Decidim.participatory_space_registry.manifests.map(&:name).each do |manifest_name|
            resources manifest_name.to_sym, only: [:show, :index], controller: "/decidim/api/rest_full/public/spaces" do
              collection do
                get "/", action: :index, defaults: { manifest_name: manifest_name }
                get "/:id", action: :show, defaults: { manifest_name: manifest_name }
              end
            end
          end
        end
      end
    end
  end
end
