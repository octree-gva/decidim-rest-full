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
            resources manifest_name.to_sym, only: [:index, :show], controller: "/decidim/api/rest_full/public/spaces", defaults: { manifest_name: manifest_name } do
              # Collection routes for the manifest
              collection do
                get "/", action: :index
              end

              # Member routes for the manifest
              member do
                get "/", action: :show

                # Dynamically add routes for components within each space
                Decidim.component_registry.manifests.each do |component|
                  component_manifest = component.name
                  scope ":component_id" do
                    resources component_manifest.to_sym, only: [:index, :show], param: :resource_id,
                                                         controller: "/decidim/api/rest_full/#{component_manifest.to_s.singularize}/#{component_manifest}",
                                                         defaults: { manifest_name: manifest_name, component_manifest_name: component_manifest } do
                      collection do
                        get "/", action: :index
                      end
                      member do
                        get "/", action: :show
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
