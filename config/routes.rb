# frozen_string_literal: true

# config/routes.rb
# Routes are drawn via RouteRegistry so domain engines can register API routes
# in the same api/rest_full/vX scope. Require domain engines before the core
# engine in lib/decidim/rest_full.rb so their blocks run when apply! is called.

CRUD_ACTIONS = [:index, :show, :update, :create, :destroy].freeze unless defined?(CRUD_ACTIONS)

Decidim::RestFull::RouteRegistry.apply!(Decidim::Core::Engine.routes) do
  get "/", to: "/decidim/rest_full/pages#show"
  post "/oauth/token", to: "/doorkeeper/tokens#create"
  post "/oauth/introspect", to: "/doorkeeper/tokens#introspect"

  resources :organizations,
            only: CRUD_ACTIONS,
            controller: "/decidim/api/rest_full/organizations/organizations" do
    member do
      resources :extended_data, only: [], controller: "/decidim/api/rest_full/organizations/organization_extended_data" do
        collection do
          get "/", action: :index
          put "/", action: :update
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
      resources :proposal_components,
                only: [:index, :show],
                controller: "/decidim/api/rest_full/components/proposal_components"
      resources :blog_components,
                only: [:index, :show],
                controller: "/decidim/api/rest_full/components/blog_components"
    end
  end

  resources :proposals,
            only: [:index, :show],
            controller: "/decidim/api/rest_full/proposals/proposals"

  resources :draft_proposals,
            only: CRUD_ACTIONS,
            controller: "/decidim/api/rest_full/draft_proposals/draft_proposals" do
    member do
      post "/publish", action: :publish
    end
  end

  resources :blogs,
            only: [:index, :show],
            controller: "/decidim/api/rest_full/blogs/blogs"

  resources :roles,
            only: [:index, :show, :create, :destroy],
            controller: "/decidim/api/rest_full/roles/roles"

  resources :proposal_votes,
            only: [:create],
            controller: "/decidim/api/rest_full/proposal_votes/proposal_votes"

  resources :users,
            only: [:index],
            controller: "/decidim/api/rest_full/users/users"

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
        end
      end
    end
  end
end
