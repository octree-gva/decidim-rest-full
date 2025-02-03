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

        # components
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

        # spaces
        resources :spaces, only: [] do 
          collection do 
            get "/search", to: "/decidim/api/rest_full/spaces/spaces#search"
            Decidim.participatory_space_registry.manifests.map(&:name).each do |manifest_name|
                resources manifest_name.to_sym, only: [:index, :show], controller: "/decidim/api/rest_full/spaces/spaces", defaults: { manifest_name: manifest_name }
            end
          end
        end

        # proposals
        resources :proposals,
        only: [:index, :show],
        controller: "/decidim/api/rest_full/proposals/proposals" 

        # draft proposals
        resources :draft_proposals,
        only: [:index, :show, :destroy, :update, :create],
        controller: "/decidim/api/rest_full/draft_proposals/draft_proposals" do 
          member do 
            post "/publish", action: :publish
          end
        end

        # blogs
        resources :blogs,
        only: [:index, :show],
        controller: "/decidim/api/rest_full/blogs/blogs" 

        # proposal votes
        resources :proposal_votes,
        only: [:create],
        controller: "/decidim/api/rest_full/proposal_votes/proposal_votes" 
        
        
        resources :me, only: [:index] do
          collection do
            post "/magic-links", to: "/decidim/api/rest_full/user/me#create_magic_link"
            get "/magic-links/:magic_token", to: "/decidim/api/rest_full/user/me#signin_magic_link"
          end
        end

        namespace :system do
          resources :organizations, only: [:index]
          resources :users,
                    only: [:index],
                    controller: "/decidim/api/rest_full/system/users" do
            get "/extended_data", to: "/decidim/api/rest_full/system/user_extended_data#show", as: :extended_data
            put "/extended_data", to: "/decidim/api/rest_full/system/user_extended_data#update"
          end
        end

        # namespace :public do
        #   resources :spaces, only: [:index]
        #   Decidim.participatory_space_registry.manifests.map(&:name).each do |manifest_name|
        #     resources manifest_name.to_sym, only: [:index, :show], controller: "/decidim/api/rest_full/public/spaces", defaults: { manifest_name: manifest_name } do
        #       # Collection routes for the manifest
        #       collection do
        #         get "/", action: :index
        #       end

        #       # Member routes for the manifest
        #       member do
        #         get "/", action: :show

        #         # Special actions, like managing proposal's drafts
        #         scope ":component_id" do
        #           resources "proposals",
        #                     only: [],
        #                     param: :resource_id,
        #                     defaults: { manifest_name: manifest_name, component_manifest_name: "proposals" } do
        #             collection do
        #               get "/draft", action: :show, controller: "/decidim/api/rest_full/proposal/draft_proposals"
        #               put "/draft", action: :update, controller: "/decidim/api/rest_full/proposal/draft_proposals"
        #               delete "/draft", action: :destroy, controller: "/decidim/api/rest_full/proposal/draft_proposals"
        #               post "/draft/publish", action: :publish, controller: "/decidim/api/rest_full/proposal/draft_proposals"
        #             end
        #             member do
        #               post "/votes", action: :create, controller: "/decidim/api/rest_full/proposal/proposal_votes"
        #             end
        #           end
        #         end

        #         # Basic get index and show on all components
        #         Decidim.component_registry.manifests.each do |component|
        #           component_manifest = component.name
        #           scope ":component_id" do
        #             resources component_manifest.to_sym, only: [:index, :show], param: :resource_id,
        #                                                  controller: "/decidim/api/rest_full/#{component_manifest.to_s.singularize}/#{component_manifest}",
        #                                                  defaults: { manifest_name: manifest_name, component_manifest_name: component_manifest } do
        #               collection do
        #                 get "/", action: :index
        #               end
        #               member do
        #                 get "/", action: :show
        #               end
        #             end
        #           end
        #         end
        #       end
        #     end
        #   end
        # end
      end
    end
  end
end
