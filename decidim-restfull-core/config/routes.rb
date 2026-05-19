# frozen_string_literal: true

# config/routes.rb
# Core API routes; Proposals/Blogs register via RouteRegistry.draw_api_routes in their engines.
# Require domain engines before Core engine in lib/decidim/rest_full.rb so draw_api_routes runs first.

CRUD_ACTIONS = [:index, :show, :update, :create, :destroy].freeze unless defined?(CRUD_ACTIONS)

Decidim::RestFull::Core::RouteRegistry.core_routes_block = proc do
  get "/", to: "/decidim/rest_full/pages#show"
  post "/oauth/token", to: "/doorkeeper/tokens#create"
  post "/oauth/introspect", to: "/doorkeeper/tokens#introspect"

  resources :jobs,
            only: [:index, :show, :destroy],
            controller: "/decidim/api/rest_full/jobs/jobs"

  resources :organizations,
            only: CRUD_ACTIONS,
            controller: "/decidim/api/rest_full/organizations/organizations" do
    member do
      put "/sync", action: :update_sync
      resources :extended_data, only: [], controller: "/decidim/api/rest_full/organizations/organization_extended_data" do
        collection do
          get "/", action: :index
          put "/", action: :update
          put "/sync", action: :update_sync
        end
      end
    end
  end

  resources :spaces, only: [] do
    collection do
      get "/search", to: "/decidim/api/rest_full/spaces/spaces#search"
      Decidim.participatory_space_registry.manifests.map(&:name).each do |manifest_name|
        resources manifest_name.to_sym, only: [:index, :show], controller: "/decidim/api/rest_full/spaces/spaces", defaults: { manifest_name: }
      end
    end
  end

  resources :components, only: [] do
    collection do
      get "/search", to: "/decidim/api/rest_full/components/components#search"
    end
  end

  resources :roles,
            only: [:index, :show, :create, :destroy],
            controller: "/decidim/api/rest_full/roles/roles" do
    collection do
      post "/sync", action: :create_sync
    end
    member do
      delete "/sync", action: :destroy_sync
    end
  end

  resources :users,
            only: [:index],
            controller: "/decidim/api/rest_full/users/users"

  constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_attachments_api }) do
    resources :attachments,
              only: CRUD_ACTIONS,
              controller: "/decidim/api/rest_full/attachments/attachments" do
      collection do
        post :direct_upload
      end
    end
  end

  resources :me, only: [] do
    collection do
      resources :magic_links, only: [:create], controller: "/decidim/api/rest_full/users/magic_links" do
        collection do
          get "/:id", action: :show, constraints: { id: /[A-Za-z0-9=]+/ }
        end
      end

      resources :extended_data, only: [], controller: "/decidim/api/rest_full/users/user_extended_data" do
        collection do
          get "/", action: :index
          put "/", action: :update
          put "/sync", action: :update_sync
        end
      end
    end
  end
end
